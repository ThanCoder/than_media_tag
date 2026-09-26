#ifndef THAN_MEDIA_TAG_H
#define THAN_MEDIA_TAG_H

#include <stdint.h>

#include "libavformat/avformat.h"
#include "libavcodec/avcodec.h"
// #include "error.h"
#include "libswscale/swscale.h"

#ifdef _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT __attribute__((visibility("default")))
#endif

/// info_log=[0=false,1=true]
FFI_PLUGIN_EXPORT
int than_decode_thumbnail_rgba(
    AVFormatContext *fmt_ctx,
    int64_t position_us,
    int target_width,
    int target_height,
    uint8_t **out_data,
    int *out_width,
    int *out_height,
    int *out_size,
    int info_log
);

FFI_PLUGIN_EXPORT
void than_free_bytes(uint8_t *data);

FFI_PLUGIN_EXPORT
const char *than_media_tag_error(int code);

#endif