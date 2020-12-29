#include <stdio.h>

class BinaryFile {
public:
	BinaryFile(const char* path);
	~BinaryFile(void);
	void WriteBuffer(void* buf, size_t size);
private:
	// I prefer using FILE* over fstream
	FILE* Handle;
};

float* ConvertFloatToDouble(double* buf, size_t len);