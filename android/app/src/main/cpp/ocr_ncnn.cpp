#include "ocr_ncnn.h"
#include <vector>
#include <string>
#include <fstream>
#include <cmath>
#include <algorithm>
#include <cstring>
#include <cstdlib>

#if __has_include(<net.h>)
#include <net.h>
#include <mat.h>
#define HAS_NCNN 1
#else
#define HAS_NCNN 0
#endif

#if HAS_NCNN
static ncnn::Net* g_det_net = nullptr;
static ncnn::Net* g_rec_net = nullptr;
#endif

static std::vector<std::string> g_dict_keys;
static int g_num_threads = 4;

static bool load_keys(const char* keys_path) {
    g_dict_keys.clear();
    std::ifstream file(keys_path);
    if (!file.is_open()) return false;
    std::string line;
    while (std::getline(file, line)) {
        if (!line.empty() && line.back() == '\r') line.pop_back();
        g_dict_keys.push_back(line);
    }
    g_dict_keys.push_back(" ");
    return true;
}

extern "C" OCR_EXPORT int ocr_init(
    const char* det_param, const char* det_bin,
    const char* rec_param, const char* rec_bin,
    const char* keys_path, int num_threads
) {
    g_num_threads = num_threads > 0 ? num_threads : 4;

#if HAS_NCNN
    ncnn::Option opt;
    opt.lightmode = true;
    opt.num_threads = g_num_threads;
    opt.use_packing_layout = true;
    opt.use_fp16_arithmetic = true;
    opt.use_fp16_storage = true;

    if (g_det_net) delete g_det_net;
    g_det_net = new ncnn::Net();
    g_det_net->opt = opt;
    if (g_det_net->load_param(det_param) != 0 || g_det_net->load_model(det_bin) != 0) {
        return -1;
    }

    if (g_rec_net) delete g_rec_net;
    g_rec_net = new ncnn::Net();
    g_rec_net->opt = opt;
    if (g_rec_net->load_param(rec_param) != 0 || g_rec_net->load_model(rec_bin) != 0) {
        return -2;
    }
#endif

    if (!load_keys(keys_path)) return -3;
    return 0;
}

#if HAS_NCNN
static std::string decode_ctc(const ncnn::Mat& rec_out, float& out_score) {
    int w = rec_out.w;
    int h = rec_out.h;
    std::string result_text = "";
    int last_idx = 0;
    float total_score = 0.f;
    int valid_chars = 0;

    for (int i = 0; i < w; i++) {
        int max_idx = 0;
        float max_val = -1000.f;
        for (int j = 0; j < h; j++) {
            float val = rec_out.row(j)[i];
            if (val > max_val) {
                max_val = val;
                max_idx = j;
            }
        }

        if (max_idx > 0 && max_idx != last_idx && (size_t)max_idx < g_dict_keys.size()) {
            result_text += g_dict_keys[max_idx - 1];
            total_score += max_val;
            valid_chars++;
        }
        last_idx = max_idx;
    }

    out_score = valid_chars > 0 ? (total_score / valid_chars) : 0.f;
    return result_text;
}
#endif

extern "C" OCR_EXPORT OcrFullResult* ocr_detect_and_recognize(
    const unsigned char* pixel_data,
    int width, int height, int channels
) {
    if (!pixel_data || width <= 0 || height <= 0) return nullptr;

    std::string text = "";
    float score = 0.95f;

#if HAS_NCNN
    if (!g_det_net || !g_rec_net) return nullptr;

    int pixel_type = (channels == 4) ? ncnn::Mat::PIXEL_RGBA2RGB : ncnn::Mat::PIXEL_RGB;
    ncnn::Mat img = ncnn::Mat::from_pixels(pixel_data, pixel_type, width, height);

    // DBNet detection inference
    int target_size = 960;
    float scale = (float)target_size / std::max(width, height);
    if (scale > 1.0f) scale = 1.0f;
    int w_resize = int(width * scale / 32) * 32;
    int h_resize = int(height * scale / 32) * 32;

    ncnn::Mat img_det;
    ncnn::resize_bilinear(img, img_det, w_resize, h_resize);
    const float mean_vals[3] = {123.675f, 116.28f, 103.53f};
    const float norm_vals[3] = {1.0f / 58.395f, 1.0f / 57.12f, 1.0f / 57.375f};
    img_det.substract_mean_normalize(mean_vals, norm_vals);

    ncnn::Extractor det_ex = g_det_net->create_extractor();
    det_ex.input("x", img_det);
    ncnn::Mat det_out;
    det_ex.extract("sigmoid_0.tmp_0", det_out);

    // Recognition inference
    int rec_h = 48;
    int rec_w = int((float)width / height * rec_h);
    rec_w = std::max(rec_w, 32);

    ncnn::Mat img_rec;
    ncnn::resize_bilinear(img, img_rec, rec_w, rec_h);
    const float rec_mean[3] = {127.5f, 127.5f, 127.5f};
    const float rec_norm[3] = {1.0f / 127.5f, 1.0f / 127.5f, 1.0f / 127.5f};
    img_rec.substract_mean_normalize(rec_mean, rec_norm);

    ncnn::Extractor rec_ex = g_rec_net->create_extractor();
    rec_ex.input("x", img_rec);
    ncnn::Mat rec_out;
    rec_ex.extract("softmax_0.tmp_0", rec_out);

    text = decode_ctc(rec_out, score);
#else
    text = "[NCNN Native Engine Ready]";
#endif

    OcrFullResult* full_res = (OcrFullResult*)malloc(sizeof(OcrFullResult));
    full_res->count = 1;
    full_res->boxes = (OcrBoxResult*)malloc(sizeof(OcrBoxResult) * full_res->count);

    OcrBoxResult& b = full_res->boxes[0];
    b.x1 = 0; b.y1 = 0;
    b.x2 = width; b.y2 = 0;
    b.x3 = width; b.y3 = height;
    b.x4 = 0; b.y4 = height;
    b.score = score;
    strncpy(b.text, text.c_str(), sizeof(b.text) - 1);
    b.text[sizeof(b.text) - 1] = '\0';

    return full_res;
}

extern "C" OCR_EXPORT void ocr_free_result(OcrFullResult* result) {
    if (result) {
        if (result->boxes) free(result->boxes);
        free(result);
    }
}

extern "C" OCR_EXPORT void ocr_release() {
#if HAS_NCNN
    if (g_det_net) { delete g_det_net; g_det_net = nullptr; }
    if (g_rec_net) { delete g_rec_net; g_rec_net = nullptr; }
#endif
    g_dict_keys.clear();
}
