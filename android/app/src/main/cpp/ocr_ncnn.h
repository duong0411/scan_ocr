#ifndef OCR_NCNN_H
#define OCR_NCNN_H

#ifdef __cplusplus
extern "C" {
#endif

#if defined(_WIN32)
    #define OCR_EXPORT __declspec(dllexport)
#else
    #define OCR_EXPORT __attribute__((visibility("default")))
#endif

typedef struct {
    int x1, y1;
    int x2, y2;
    int x3, y3;
    int x4, y4;
    char text[512];
    float score;
} OcrBoxResult;

typedef struct {
    int count;
    OcrBoxResult* boxes;
} OcrFullResult;

OCR_EXPORT int ocr_init(
    const char* det_param_path,
    const char* det_bin_path,
    const char* rec_param_path,
    const char* rec_bin_path,
    const char* keys_path,
    int num_threads
);

OCR_EXPORT OcrFullResult* ocr_detect_and_recognize(
    const unsigned char* pixel_data,
    int width,
    int height,
    int channels
);

OCR_EXPORT void ocr_free_result(OcrFullResult* result);

OCR_EXPORT void ocr_release();

#ifdef __cplusplus
}
#endif

#endif // OCR_NCNN_H
