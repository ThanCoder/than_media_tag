#include "than_media_tag.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define THAN_LOG_ERROR(name, code)                                             \
  fprintf(stderr, "[thumb] %s failed: %s (%d)\n", name,                        \
          than_media_tag_error(code), code)

#define THAN_LOG_INFO(...) fprintf(stderr, "[thumb] " __VA_ARGS__)


int than_decode_thumbnail_rgba(AVFormatContext *fmt_ctx, int64_t position_us,
                               int target_width, int target_height,
                               uint8_t **out_data, int *out_width,
                               int *out_height, int *out_size, int info_log) {
  int ret = 0;

  AVCodecContext *codec_ctx = NULL;
  AVPacket *packet = NULL;
  AVFrame *frame = NULL;
  AVFrame *rgba_frame = NULL;

  struct SwsContext *sws_ctx = NULL;

  const AVCodec *decoder = NULL;
  AVStream *stream = NULL;

  uint8_t *buffer = NULL;

  // ------------------------------------------------------------
  // Validate arguments
  // ------------------------------------------------------------

  if (!fmt_ctx || !out_data || !out_width || !out_height || !out_size) {
    return AVERROR(EINVAL);
  }

  *out_data = NULL;
  *out_width = 0;
  *out_height = 0;
  *out_size = 0;

  // ------------------------------------------------------------
  // Find video stream
  // ------------------------------------------------------------

  int stream_index =
      av_find_best_stream(fmt_ctx, AVMEDIA_TYPE_VIDEO, -1, -1, &decoder, 0);

  if (stream_index < 0) {
    if (info_log == 1) {
      THAN_LOG_ERROR("av_find_best_stream", stream_index);
    }
    return stream_index;
  }

  stream = fmt_ctx->streams[stream_index];
  if (info_log == 1) {

    THAN_LOG_INFO("stream=%d codec=%s position=%lldus\n", stream_index,
                  decoder ? decoder->name : "unknown", (long long)position_us);
  }

  // ------------------------------------------------------------
  // Decoder context
  // ------------------------------------------------------------

  codec_ctx = avcodec_alloc_context3(decoder);

  if (!codec_ctx) {
    if (info_log == 1) {
      THAN_LOG_ERROR("avcodec_alloc_context3", ret);
    }
    ret = AVERROR(ENOMEM);
    goto cleanup;
  }

  ret = avcodec_parameters_to_context(codec_ctx, stream->codecpar);

  if (ret < 0) {
    if (info_log == 1) {
      THAN_LOG_ERROR("avcodec_parameters_to_context", ret);
    }
    goto cleanup;
  }

  ret = avcodec_open2(codec_ctx, decoder, NULL);

  if (ret < 0) {
    if (info_log == 1) {
      THAN_LOG_ERROR("avcodec_open2", ret);
    }
    goto cleanup;
  }
  if (info_log == 1) {
    THAN_LOG_INFO("decoder opened: %dx%d format=%d\n", codec_ctx->width,
                  codec_ctx->height, codec_ctx->pix_fmt);
  }
  // ------------------------------------------------------------
  // Seek
  // ------------------------------------------------------------

  int64_t timestamp = av_rescale_q(position_us, (AVRational){1, AV_TIME_BASE},
                                   stream->time_base);

  ret = av_seek_frame(fmt_ctx, stream_index, timestamp, AVSEEK_FLAG_BACKWARD);

  if (ret < 0) {
    if (info_log == 1) {
      THAN_LOG_ERROR("av_seek_frame", ret);
    }
    goto cleanup;
  }

  avcodec_flush_buffers(codec_ctx);

  // ------------------------------------------------------------
  // Allocate packet/frame
  // ------------------------------------------------------------

  packet = av_packet_alloc();
  frame = av_frame_alloc();

  if (!packet || !frame) {
    if (info_log == 1) {
      THAN_LOG_ERROR("av_packet_alloc/av_frame_alloc", ret);
    }
    ret = AVERROR(ENOMEM);
    goto cleanup;
  }

  // ------------------------------------------------------------
  // Decode
  // ------------------------------------------------------------

  int got_frame = 0;

  while (!got_frame) {
    ret = av_read_frame(fmt_ctx, packet);

    if (ret < 0) {
      if (info_log == 1) {
        THAN_LOG_ERROR("av_read_frame", ret);
      }
      goto cleanup;
    }

    if (packet->stream_index != stream_index) {
      av_packet_unref(packet);
      continue;
    }

    ret = avcodec_send_packet(codec_ctx, packet);

    av_packet_unref(packet);

    if (ret < 0) {
      if (info_log == 1) {
        THAN_LOG_ERROR("avcodec_send_packet", ret);
      }
      goto cleanup;
    }

    while (1) {
      ret = avcodec_receive_frame(codec_ctx, frame);

      if (ret == AVERROR(EAGAIN)) {
        break;
      }

      if (ret == AVERROR_EOF) {
        if (info_log == 1) {
          THAN_LOG_ERROR("avcodec_receive_frame", ret);
        }
        goto cleanup;
      }

      if (ret < 0) {
        if (info_log == 1) {
          THAN_LOG_ERROR("avcodec_receive_frame", ret);
        }
        goto cleanup;
      }

      got_frame = 1;
      if (info_log == 1) {
        THAN_LOG_INFO("frame decoded: %dx%d format=%d linesize=%d\n",
                      frame->width, frame->height, frame->format,
                      frame->linesize[0]);
      }
      break;
    }
  }

  if (!got_frame) {
    ret = AVERROR(EINVAL);
    if (info_log == 1) {
      THAN_LOG_ERROR("decode", ret);
    }
    goto cleanup;
  }

  // ------------------------------------------------------------
  // Source dimensions
  // ------------------------------------------------------------

  int src_width = frame->width;
  int src_height = frame->height;

  if (src_width <= 0 || src_height <= 0) {
    ret = AVERROR(EINVAL);
    if (info_log == 1) {
      THAN_LOG_ERROR("invalid source dimensions", ret);
    }
    goto cleanup;
  }

  // ------------------------------------------------------------
  // Calculate output dimensions
  // ------------------------------------------------------------

  if (target_width <= 0 && target_height <= 0) {
    target_width = src_width;
    target_height = src_height;
  } else if (target_width <= 0) {
    target_width = (int)(((int64_t)src_width * target_height) / src_height);
  } else if (target_height <= 0) {
    target_height = (int)(((int64_t)src_height * target_width) / src_width);
  }

  if (target_width <= 0 || target_height <= 0) {
    ret = AVERROR(EINVAL);
    if (info_log == 1) {
      THAN_LOG_ERROR("invalid target dimensions", ret);
    }
    goto cleanup;
  }
  if (info_log == 1) {
    THAN_LOG_INFO("scale: %dx%d fmt=%d -> %dx%d RGBA\n", src_width, src_height,
                  frame->format, target_width, target_height);
  }
  // ------------------------------------------------------------
  // Allocate RGBA frame
  // ------------------------------------------------------------

  rgba_frame = av_frame_alloc();

  if (!rgba_frame) {
    ret = AVERROR(ENOMEM);
    THAN_LOG_ERROR("av_frame_alloc(rgba)", ret);
    goto cleanup;
  }

  rgba_frame->format = AV_PIX_FMT_RGBA;
  rgba_frame->width = target_width;
  rgba_frame->height = target_height;

  ret = av_frame_get_buffer(rgba_frame, 32);

  if (ret < 0) {
    if (info_log == 1) {
      THAN_LOG_ERROR("av_frame_get_buffer(rgba)", ret);
    }
    goto cleanup;
  }

  // ------------------------------------------------------------
  // SwScale
  // ------------------------------------------------------------

  sws_ctx = sws_getContext(src_width, src_height, frame->format,

                           target_width, target_height, AV_PIX_FMT_RGBA,

                           SWS_BILINEAR,

                           NULL, NULL, NULL);

  if (!sws_ctx) {
    ret = AVERROR(EINVAL);
    if (info_log == 1) {
      fprintf(stderr,
              "[thumb] sws_getContext failed: "
              "%dx%d fmt=%d -> %dx%d RGBA\n",
              src_width, src_height, frame->format, target_width,
              target_height);
    }
    goto cleanup;
  }

  // ------------------------------------------------------------
  // Convert to RGBA
  // ------------------------------------------------------------

  ret = sws_scale(sws_ctx,

                  (const uint8_t *const *)frame->data, frame->linesize,

                  0, src_height,

                  rgba_frame->data, rgba_frame->linesize);

  if (ret <= 0) {
    ret = AVERROR(EINVAL);
    if (info_log == 1) {
      THAN_LOG_ERROR("sws_scale", ret);
    }
    goto cleanup;
  }

  // ------------------------------------------------------------
  // Allocate contiguous RGBA buffer
  // ------------------------------------------------------------

  int width = target_width;
  int height = target_height;

  int64_t rgba_size_64 = (int64_t)width * (int64_t)height * 4;

  if (rgba_size_64 <= 0 || rgba_size_64 > INT32_MAX) {
    ret = AVERROR(EINVAL);
    if (info_log == 1) {
      THAN_LOG_ERROR("invalid RGBA buffer size", ret);
    }
    goto cleanup;
  }

  int rgba_size = (int)rgba_size_64;

  buffer = malloc((size_t)rgba_size);

  if (!buffer) {
    ret = AVERROR(ENOMEM);
    if (info_log == 1) {
      THAN_LOG_ERROR("malloc RGBA buffer", ret);
    }
    goto cleanup;
  }

  // ------------------------------------------------------------
  // Remove AVFrame padding/stride
  // ------------------------------------------------------------

  for (int y = 0; y < height; y++) {
    uint8_t *src = rgba_frame->data[0] + ((size_t)y * rgba_frame->linesize[0]);

    uint8_t *dst = buffer + ((size_t)y * width * 4);

    memcpy(dst, src, (size_t)width * 4);
  }

  // ------------------------------------------------------------
  // Return
  // ------------------------------------------------------------

  *out_data = buffer;
  *out_width = width;
  *out_height = height;
  *out_size = rgba_size;
  if (info_log == 1) {
    THAN_LOG_INFO("success: %dx%d RGBA size=%d\n", width, height, rgba_size);
  }
  buffer = NULL;
  ret = 0;

cleanup:

  if (buffer) {
    free(buffer);
  }

  if (sws_ctx) {
    sws_freeContext(sws_ctx);
  }

  if (rgba_frame) {
    av_frame_free(&rgba_frame);
  }

  if (frame) {
    av_frame_free(&frame);
  }

  if (packet) {
    av_packet_free(&packet);
  }

  if (codec_ctx) {
    avcodec_free_context(&codec_ctx);
  }

  return ret;
}

void than_free_bytes(uint8_t *data) {
  if (data) {
    free(data);
  }
}

const char *than_media_tag_error(int code) {
  static char buffer[AV_ERROR_MAX_STRING_SIZE];

  av_strerror(code, buffer, sizeof(buffer));

  return buffer;
}