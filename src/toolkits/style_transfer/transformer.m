#include <toolkits/style_transfer/transformer.h>
#include <ml/neural_net/mps_layer_helper.h>

@implementation TransformerModel

- (id _Nonnull) initWithParameters:(NSString * _Nullable)name
                         inputNode:(MPSNNImageNode * _Nonnull)inputNode
                            device:(id<MTLDevice> _Nonnull)dev
                         cmd_queue:(id<MTLCommandQueue> _Nonnull)cmd_q
                       initWeights:(struct TransformerWeights)weights {
  @autoreleasepool {
    self = [super init];

    encoding_1 = [[Encoding alloc] initWithParameters:@"transformer_encode_1"
                                            inputNode:inputNode
                                               device:dev
                                            cmd_queue:cmd_q
                                          initWeights:weights.encode_1];

    encoding_2 = [[Encoding alloc] initWithParameters:@"transformer_encode_2"
                                            inputNode:[encoding_1 forwardPass]
                                               device:dev
                                            cmd_queue:cmd_q
                                          initWeights:weights.encode_2];

    encoding_3 = [[Encoding alloc] initWithParameters:@"transformer_encode_3"
                                            inputNode:[encoding_2 forwardPass]
                                               device:dev
                                            cmd_queue:cmd_q
                                          initWeights:weights.encode_3];

    residual_1 = [[Residual alloc] initWithParameters:@"transformer_residual_1"
                                            inputNode:[encoding_3 forwardPass]
                                               device:dev
                                            cmd_queue:cmd_q
                                          initWeights:weights.residual_1];

    residual_2 = [[Residual alloc] initWithParameters:@"transformer_residual_2"
                                            inputNode:[residual_1 forwardPass]
                                               device:dev
                                            cmd_queue:cmd_q
                                          initWeights:weights.residual_2];

    residual_3 = [[Residual alloc] initWithParameters:@"transformer_residual_3"
                                            inputNode:[residual_2 forwardPass]
                                               device:dev
                                            cmd_queue:cmd_q
                                          initWeights:weights.residual_2];

    residual_4 = [[Residual alloc] initWithParameters:@"transformer_residual_4"
                                            inputNode:[residual_3 forwardPass]
                                               device:dev
                                            cmd_queue:cmd_q
                                          initWeights:weights.residual_4];

    residual_5 = [[Residual alloc] initWithParameters:@"transformer_residual_5"
                                            inputNode:[residual_4 forwardPass]
                                               device:dev
                                            cmd_queue:cmd_q
                                          initWeights:weights.residual_5];

    decoding_1 = [[Decoding alloc] initWithParameters:@"transformer_decoding_1"
                                            inputNode:[residual_5 forwardPass]
                                               device:dev
                                            cmd_queue:cmd_q
                                          initWeights:weights.decode_1];

    decoding_2 = [[Decoding alloc] initWithParameters:@"transformer_decoding_2"
                                            inputNode:[decoding_1 forwardPass]
                                               device:dev
                                            cmd_queue:cmd_q
                                          initWeights:weights.decode_2];

    conv = [TCMPSLayerHelper createConvolutional:[decoding_2 forwardPass]
                                     kernelWidth:weights.conv.kernelWidth
                                    kernelHeight:weights.conv.kernelHeight
                            inputFeatureChannels:weights.conv.inputFeatureChannels
                           outputFeatureChannels:weights.conv.outputFeatureChannels
                                     strideWidth:weights.conv.strideWidth
                                    strideHeight:weights.conv.strideHeight
                                    paddingWidth:weights.conv.paddingWidth
                                   paddingHeight:weights.conv.paddingHeight
                                         weights:weights.conv.weights
                                          biases:weights.conv.biases
                                           label:weights.conv.label
                                   updateWeights:weights.conv.updateWeights
                                          device:dev
                                       cmd_queue:cmd_q];

    inst_norm = [TCMPSLayerHelper createInstanceNormalization:[conv resultImage]
                                                     channels:weights.inst.channels
                                                       styles:weights.inst.styles
                                                        gamma:weights.inst.gamma
                                                         beta:weights.inst.beta
                                                        label:weights.inst.label
                                                       device:dev
                                                    cmd_queue:cmd_q];

    sigmoid = [MPSCNNNeuronSigmoidNode nodeWithSource:[inst_norm resultImage]];

    m_output = [sigmoid resultImage];

    return self;
  }
}

- (MPSNNImageNode * _Nullable) forwardPass {
  return m_output;
}

- (MPSNNImageNode * _Nullable) backwardPass:(MPSNNImageNode * _Nonnull)inputNode {
  MPSNNGradientFilterNode* sigmoid_grad = [sigmoid gradientFilterWithSource: inputNode];
  MPSNNGradientFilterNode* instance_norm_grad = [inst_norm gradientFilterWithSource: [sigmoid_grad resultImage]];
  MPSNNGradientFilterNode* conv_grad = [conv gradientFilterWithSource: [instance_norm_grad resultImage]];

  MPSNNImageNode* decoding_2_img = [decoding_2 backwardPass:[conv_grad resultImage]];
  MPSNNImageNode* decoding_1_img = [decoding_1 backwardPass:decoding_2_img];

  MPSNNImageNode* residual_5_img = [residual_5 backwardPass:decoding_1_img];
  MPSNNImageNode* residual_4_img = [residual_4 backwardPass:residual_5_img];
  MPSNNImageNode* residual_3_img = [residual_3 backwardPass:residual_4_img];
  MPSNNImageNode* residual_2_img = [residual_2 backwardPass:residual_3_img];
  MPSNNImageNode* residual_1_img = [residual_1 backwardPass:residual_2_img];

  MPSNNImageNode* encoding_3_grad = [encoding_3 backwardPass:residual_1_img];
  MPSNNImageNode* encoding_2_grad = [encoding_2 backwardPass:encoding_3_grad];
  MPSNNImageNode* encoding_1_grad = [encoding_1 backwardPass:encoding_2_grad];
  
  return encoding_1_grad;
}

@end