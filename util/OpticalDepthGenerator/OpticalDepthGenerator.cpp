/*
This based off Sean O'Neil's article in GPU Gems 2
https://developer.nvidia.com/gpugems/gpugems2/part-ii-shading-lighting-and-shadows/chapter-16-accurate-atmospheric-scattering
In Sean O'Neil's implementation:
The X texture coordinate represents a height
The Y texture coordinate represents a vertical angle from -1 to 1
The R channel is Rayleigh density at altitude X
The G channel is Mie density at altitude X
The B channel is Rayleigh optical depth at altitude X looking at vertical angle Y
The A channel is Mie optical depth at altitude X looking at vertical angle Y
In my implementation:
The X texture coordinate represents a height
The Y texture coordinate represents a vertical angle from -1 to 1
The R channel is Rayleigh optical depth at altitude X looking at vertical angle Y
The G channel is Mie optical depth at altitude X looking at vertical angle Y
The A channel is Ozone optical depth at altitude X looking at vertical angle Y
The height can be stored in an different 1D LUT, so I don't know why O'Neil stored it in a 2D texture
But in Optifine, we have limited texture space so I would have to store the 1D LUT and 2D LUT together in a 3D texture
*/

#include <BinaryFileUtil.h>
#include <math.h>
#include <iostream>
#include <thread>
#include <ios>
#include <mutex>
#include <chrono>

const int LUT_Resolution = 512;
const int LUT_Size = LUT_Resolution * LUT_Resolution;
const int OpticalDepthSamples = 1024; // Since I'm too lazy to do trapezoidal integration
const double ScaleHeightRayleigh = 7994.0;
const double ScaleHeightMie = 1200.0;
const double EarthRadius = 6360.0e3;
const double AtmosphereHeight = 80.0e3;
const double AtmosphereRadius = AtmosphereHeight + EarthRadius;

std::mutex ConsoleMutex;

struct StopWatch {
	StopWatch(void) {
		Start = std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::system_clock::now().time_since_epoch()).count();
	}
	~StopWatch(void) {
		int64_t End = std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::system_clock::now().time_since_epoch()).count();
		double Duration = (double)(End - Start);
		Duration /= 1000.0;
		std::cout << "Computation took " << Duration << " seconds\n";
	}
	int64_t Start;
};

struct Density {
	double Rayleigh;
	double Mie;
	double Ozone;
	Density(void) : Rayleigh(0.0f), Mie(0.0), Ozone(0.0) {}
	Density operator+(const Density& other) {
		Density out;
		out.Rayleigh = Rayleigh + other.Rayleigh;
		out.Mie      = Mie      + other.Mie     ;
		out.Ozone    = Ozone    + other.Ozone   ;
		return out;
	}
	void operator+=(const Density& other) {
		*this = *this + other;
	}
	Density operator/(double val) {
		Density out;
		out.Rayleigh = Rayleigh / val;
		out.Mie      = Mie      / val;
		out.Ozone    = Ozone    / val;
		return out;
	}
	Density operator*(double val) {
		Density out;
		out.Rayleigh = Rayleigh * val;
		out.Mie = Mie * val;
		out.Ozone = Ozone * val;
		return out;
	}
};

typedef Density OpticalDepth;
OpticalDepth* TextureData;

inline Density SampleDensity(double altitude) {
	altitude = fmax(altitude, -800.0);
	Density CurrentDensity;
	CurrentDensity.Rayleigh = exp(-altitude / ScaleHeightRayleigh);
	CurrentDensity.Mie      = exp(-altitude / ScaleHeightMie     );
	CurrentDensity.Ozone    = altitude / 1000.0; // The function squares x, and x is supposed to be in km
	CurrentDensity.Ozone    = CurrentDensity.Ozone - 29.874;
	CurrentDensity.Ozone   *= CurrentDensity.Ozone;
	CurrentDensity.Ozone    = 1.0 / (1.0 + CurrentDensity.Ozone);
	CurrentDensity.Ozone    = pow(CurrentDensity.Ozone, 0.7);
	CurrentDensity.Ozone   *= 0.07;
	return CurrentDensity;
}

template<typename T>
class Texture1D {
public:
	size_t Size = 0;
	T* Data = nullptr;
	Texture1D(size_t elements) : Size(elements), Data(new T[elements]) {}
	~Texture1D(void) {
		delete[] Data;
	}
	void TexelWrite(uint32_t index, const T& val) {
		Data[index] = val;
	}
	T TexelRead(uint32_t index) {
		if (index > Size) {
			index = Size;
		}
		if (index < 0) {
			index = 0;
		}
		return Data[index];
	}
	T Read(double coord) {
		double TexelCoord = Size * coord;
		uint32_t Lower = floor(TexelCoord);
		uint32_t Upper = ceil(TexelCoord);

		T& Val0 = TexelRead(Lower);
		T& Val1 = TexelRead(Upper);
		float MixFactor = TexelCoord - Lower;
		return (Val0 * MixFactor) + (Val1 * (1.0 - MixFactor));
	}
};

static Texture1D<Density> DensityLUT = Texture1D<Density>(LUT_Resolution * OpticalDepthSamples);
struct DensityLUT_Init {
	DensityLUT_Init(void) {
		for (uint32_t Index = 0; Index < DensityLUT.Size; Index++) {
			double Altitude = AtmosphereHeight * ((double)Index / (double)DensityLUT.Size);
			DensityLUT.TexelWrite(Index, SampleDensity(Altitude));
		}
	}
}DensityLUT_Init_;

struct Vec3f {
	double x, y, z;
	Vec3f operator*(double dist) {
		Vec3f ret;
		ret.x = x * dist;
		ret.y = y * dist;
		ret.z = z * dist;
		return ret;
	}
	Vec3f operator/(double div) {
		Vec3f ret;
		ret.x = x / div;
		ret.y = y / div;
		ret.z = z / div;
		return ret;
	}
	Vec3f operator+(const Vec3f& other) {
		Vec3f ret;
		ret.x = other.x + x;
		ret.y = other.y + y;
		ret.z = other.z + z;
		return ret;
	}
	Vec3f operator-(const Vec3f& other) {
		Vec3f ret;
		ret.x = x - other.x;
		ret.y = y - other.y;
		ret.z = z - other.z;
		return ret;
	}
	double length(void) {
		return sqrt(x * x + y * y + z * z);
	}
	void normalize(void) {
		*this = *this / length();
	}
};

// https://www.scratchapixel.com/code.php?id=52&origin=/lessons/procedural-generation-virtual-worlds/simulating-sky
bool SolveQuadratic(double a, double b, double c, double& x1, double& x2)
{
	if (b == 0) {
		// Handle special case where the the two vector ray.dir and V are perpendicular
		// with V = ray.orig - sphere.centre
		if (a == 0) return false;
		x1 = 0; x2 = std::sqrt(-c / a);
		return true;
	}
	double discr = b * b - 4 * a * c;

	if (discr < 0) return false;

	double q = (b < 0.f) ? -0.5f * (b - std::sqrt(discr)) : -0.5f * (b + std::sqrt(discr));
	x1 = q / a;
	x2 = c / q;

	return true;
}

// https://www.scratchapixel.com/code.php?id=52&origin=/lessons/procedural-generation-virtual-worlds/simulating-sky
bool RaySphereIntersect(const Vec3f& orig, const Vec3f& dir, const double& radius, double& t0, double& t1)
{
	// They ray dir is normalized so A = 1 
	double A = dir.x * dir.x + dir.y * dir.y + dir.z * dir.z;
	double B = 2 * (dir.x * orig.x + dir.y * orig.y + dir.z * orig.z);
	double C = orig.x * orig.x + orig.y * orig.y + orig.z * orig.z - radius * radius;

	if (!SolveQuadratic(A, B, C, t0, t1)) return false;

	if (t0 > t1) std::swap(t0, t1);

	return true;
}

inline OpticalDepth ComputeOpticalDepth(double height, double vertical_angle) {
	//vertical_angle = abs(vertical_angle);
	OpticalDepth AccumOpticalDepth;
	Vec3f Origin;
	Origin.x = 0.0;
	Origin.y = height + EarthRadius;
	Origin.z = 0.0;
	Vec3f Direction;
	Direction.x = sin(acos(vertical_angle));
	Direction.y = vertical_angle;
	Direction.z = 0.0f;
	Direction.normalize();
	double AtmosphereDist0, AtmosphereDist1;
	RaySphereIntersect(Origin, Direction, AtmosphereRadius, AtmosphereDist0, AtmosphereDist1);
	// double EarthDist0, EarthDist1; if (RaySphereIntersect(Origin, Direction, EarthRadius, EarthDist0, EarthDist1)) AtmosphereDist1 = EarthDist1;
	Vec3f StartPos = Origin;
	double RayMarchStepLength = AtmosphereDist1 / OpticalDepthSamples;
	double RayMarchPosition = 0.0f;
	for (int Sample = 0; Sample < OpticalDepthSamples; Sample++) {
		Vec3f SamplePosition = StartPos + Direction * (RayMarchPosition + RayMarchStepLength * 0.5);
		double altitude = SamplePosition.length() - EarthRadius;
		AccumOpticalDepth += SampleDensity(altitude);
		RayMarchPosition += RayMarchStepLength;
	}
	AccumOpticalDepth = AccumOpticalDepth * RayMarchStepLength;
	return AccumOpticalDepth;
}

void ProcessRow(int y) {
	ConsoleMutex.lock();
	std::cout << "Computing row " << y << '\n';
	ConsoleMutex.unlock();
	int offset = y * LUT_Resolution;
	double vertical_angle = ((double)y / (double)LUT_Resolution) * 2.0 - 1.0;
	for (int x = 0; x < LUT_Resolution; x++) {
		double height = AtmosphereHeight * ((double)x / (double)LUT_Resolution);
		TextureData[offset + x] = ComputeOpticalDepth(height, vertical_angle);
	}
	ConsoleMutex.lock();
	std::cout << "Done Computing row " << y << '\n';
	ConsoleMutex.unlock();
}

int main() {
	StopWatch TimeCounter;
	std::ios::sync_with_stdio(false);
	TextureData = new OpticalDepth[LUT_Size];
	std::thread** WorkerThreads = new std::thread*[LUT_Resolution];
	for (int y = 0; y < LUT_Resolution; y++) {
		WorkerThreads[y] = new std::thread(ProcessRow, y);
	}
	for (int y = 0; y < LUT_Resolution; y++) {
		WorkerThreads[y]->join();
	}
	delete[] WorkerThreads;
	float* BinaryData = ConvertFloatToDouble((double*)TextureData, LUT_Size * sizeof(OpticalDepth) / sizeof(double)); // 3 doubles per optical depth, evals to 3
	BinaryFile File("OpticalDepth.dat"); // ../../shaders/lib/Resources/
	File.WriteBuffer(BinaryData, 3 * LUT_Size * sizeof(float));
	delete[] BinaryData;
	delete[] TextureData;
	return 0;
}