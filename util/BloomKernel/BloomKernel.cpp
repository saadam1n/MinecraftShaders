#include <stdio.h>
#include <math.h>

const float StandardDeviation = 5.5f                   ;
const int   KernelSamples     = 15                     ;
const int   KernelSize          = KernelSamples * 2 + 1;

float Gaussian(float stddev, float x) {
    float stddev2 = stddev * stddev;
    float stddev2_2 = stddev2 * 2.0f;
    return pow(3.141529 * stddev2_2, -0.5f) * exp(-(x * x / stddev2_2));
}

int main() {
    FILE* KernelWrite = fopen("../../shaders/lib/Kernel/Bloom.glsl", "w+");
    fprintf(KernelWrite, "#ifndef KERNEL_BLOOM_GLSL\n#define KERNEL_BLOOM_GLSL 1\n\nconst float KernelBloom[] = float[](\n\t");
    float Normalizer = 0.0f;
    float Kernel[KernelSize];
    for (int KernelDistance = -KernelSamples; KernelDistance <= KernelSamples; KernelDistance++) {
        float GaussianWeight = Gaussian(StandardDeviation, KernelDistance);
        Normalizer += GaussianWeight;
        Kernel[KernelDistance + KernelSamples] = GaussianWeight;
    }  
    for (int index = 0; index < KernelSize; index++) {
        float Val = Kernel[index];
        Val /= Normalizer;
        fprintf(KernelWrite, "%1.20ff", Val);
        if (index != KernelSize - 1) {
            fprintf(KernelWrite, ",\n\t");
        }
        printf("%1.20f\n", Val);
    }
    fprintf(KernelWrite, "\n);\n\n#endif");
    fclose(KernelWrite);
}