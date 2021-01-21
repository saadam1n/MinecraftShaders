#include <stdio.h>
#include <math.h>

float Gaussian(double stddev, double x) {
    float stddev2 = stddev * stddev;
    float stddev2_2 = stddev2 * 2.0f;
    return pow(3.141529 * stddev2_2, -0.5f) * exp(-(x * x / stddev2_2));
}

static double Sigma;
static int Samples;

int main() {
    while (true) {
        printf("Enter the number of samples\n");
        scanf("%i", &Samples);
        printf("Enter the standard deviation\n");
        scanf("%lf", &Sigma);
        printf("Creating kernel with size of %i and standard deviation of %lf\n", Samples, Sigma);
        int Size = (Samples - 1) / 2;
        double Normalizer = 0.0;
        double* Kernel = new double[Samples] { -1.0f };
        for (int KernelDistance = -Size; KernelDistance <= Size; KernelDistance++) {
            float GaussianWeight = Gaussian(Sigma, KernelDistance);
            Normalizer += GaussianWeight;
            Kernel[KernelDistance + Size] = GaussianWeight;
        }
        printf("Your 1D Gausian kernel is:\nconst float Kernel[] = float[] (\n\t");
        for (int index = 0; index < Samples; index++) {
            double Val = Kernel[index];
            Val /= Normalizer;
            printf("%1.20lff", Val);
            if (index != Samples - 1) {
                printf(",\n\t");
            }
            else {
                printf("\n);\n\n");
            }
        }
        delete[] Kernel;
    }
}