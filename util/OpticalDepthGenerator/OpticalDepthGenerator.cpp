#include <BinaryFileUtil.h>
#include <math.h>
#include <iostream>
#include <thread>
#include <ios>
#include <mutex>
#include <chrono>

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

const int LUT_Resolution = 2048;
const int LUT_Size = LUT_Resolution * LUT_Resolution;
const int OpticalDepthSamples = 1024; // Since I'm too lazy to do trapezoidal integration

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
};

typedef Density OpticalDepth;
OpticalDepth* TextureData;

const double ScaleHeightRayleigh = 7994.0;
const double ScaleHeightMie = 1200.0;

const double AtmosphereHeight = 80000.0;

inline Density SampleDensity(double altitude) {
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

inline OpticalDepth ComputeOpticalDepth(double height0, double height1) {
	OpticalDepth AccumOpticalDepth;
	double HeightStep = (height1 - height0) / (double)OpticalDepthSamples;
	double HeightPos = height0;
	for (int sample = 0; sample < OpticalDepthSamples; sample++) {
		float SampleLocation = height0 + HeightPos + 0.5 * HeightStep;
		// Divide here instead for minimal floating point error
		Density CurrentDensity = SampleDensity(SampleLocation);
		AccumOpticalDepth = AccumOpticalDepth + CurrentDensity / (double)OpticalDepthSamples;
		HeightPos += HeightStep;
	}
	return AccumOpticalDepth;
}

void ProcessRow(int y) {
	ConsoleMutex.lock();
	std::cout << "Computing row " << y << '\n';
	ConsoleMutex.unlock();
	int offset = y * LUT_Resolution;
	double height1 = AtmosphereHeight * (double)y / (double)LUT_Resolution;
	for (int x = 0; x < LUT_Resolution; x++) {
		double height0 = AtmosphereHeight * (double)x / (double)LUT_Resolution;
		TextureData[offset + x] = ComputeOpticalDepth(height0, height1);
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
	BinaryFile File("../../shaders/lib/Resources/OpticalDepth.dat");
	File.WriteBuffer(BinaryData, 3 * LUT_Size * sizeof(float));
	delete[] BinaryData;
	delete[] TextureData;
	return 0;
}