#ifndef TURI_STYLE_TRANSFER_UTILS_H_
#define TURI_STYLE_TRANSFER_UTILS_H_

struct ConvolutionWeights {
  int kernelWidth;
  int kernelHeight;
  int inputFeatureChannels;
  int outputFeatureChannels;
  int strideWidth;
  int strideHeight;
  int paddingWidth;
  int paddingHeight;
  float * _Nonnull weights;
  float * _Nonnull biases;
  NSString * _Nonnull label;
  bool updateWeights;
};

struct InstanceNormalizationWeights {
  int channels;
  int styles;
  float * _Nonnull * _Nonnull gamma;
  float * _Nonnull * _Nonnull beta;
  NSString * _Nonnull label;
};

struct UpsamplingWeights {
  int scale;
};

struct PoolingWeights {
  int kernelSize;
  int strideSize;
};

struct EncodingWeights {
  struct ConvolutionWeights conv;
  struct InstanceNormalizationWeights inst;
};

struct ResidualWeights {
  struct ConvolutionWeights conv_1;
  struct ConvolutionWeights conv_2;
  struct InstanceNormalizationWeights inst_1;
  struct InstanceNormalizationWeights inst_2;
};

struct DecodingWeights {
  struct ConvolutionWeights conv;
  struct InstanceNormalizationWeights inst;
  struct UpsamplingWeights upsample;
};

struct Block1Weights {
  struct ConvolutionWeights conv_1;
  struct ConvolutionWeights conv_2;
  struct PoolingWeights pooling;
};

struct Block2Weights {
  struct ConvolutionWeights conv_1;
  struct ConvolutionWeights conv_2;
  struct ConvolutionWeights conv_3;
  struct PoolingWeights pooling;
};

struct Vgg16Weights {
  struct Block1Weights block_1;
  struct Block1Weights block_2;
  struct Block2Weights block_3;
  struct Block2Weights block_4;
};

struct StyleTransferWeights {
  struct EncodingWeights encode_1;
  struct EncodingWeights encode_2;
  struct EncodingWeights encode_3;

  struct ResidualWeights residual_1;
  struct ResidualWeights residual_2;
  struct ResidualWeights residual_3;
  struct ResidualWeights residual_4;
  struct ResidualWeights residual_5;

  struct DecodingWeights decode_1;
  struct DecodingWeights decode_2;

  struct ConvolutionWeights conv;
  struct InstanceNormalizationWeights inst;
};


#endif