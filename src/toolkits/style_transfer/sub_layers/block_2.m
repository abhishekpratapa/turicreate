#include <toolkits/style_transfer/sub_layers/block_2.h>
#include <ml/neural_net/mps_layer_helper.h>

@implementation Block2

- (id _Nonnull) initWithParameters:(NSString * _Nullable)name
                         inputNode:(MPSNNImageNode * _Nonnull)inputNode
                            device:(id<MTLDevice> _Nonnull)dev
                         cmd_queue:(id<MTLCommandQueue> _Nonnull)cmd_q
                       initWeights:(struct Block2Weights)weights {
  @autoreleasepool {
    self = [super init];

    conv_1 = [TCMPSLayerHelper createConvolutional:inputNode
                                       kernelWidth:weights.conv_1.kernelWidth
                                      kernelHeight:weights.conv_1.kernelHeight
                              inputFeatureChannels:weights.conv_1.inputFeatureChannels
                             outputFeatureChannels:weights.conv_1.outputFeatureChannels
                                       strideWidth:weights.conv_1.strideWidth
                                      strideHeight:weights.conv_1.strideHeight
                                      paddingWidth:weights.conv_1.paddingWidth
                                     paddingHeight:weights.conv_1.paddingHeight
                                           weights:weights.conv_1.weights
                                            biases:weights.conv_1.biases
                                             label:weights.conv_1.label
                                     updateWeights:weights.conv_1.updateWeights
                                            device:dev
                                         cmd_queue:cmd_q];

    relu_1 = [MPSCNNNeuronReLUNNode nodeWithSource: [conv_1 resultImage]];
    
    conv_2 = [TCMPSLayerHelper createConvolutional:[relu_1 resultImage]
                                       kernelWidth:weights.conv_2.kernelWidth
                                      kernelHeight:weights.conv_2.kernelHeight
                              inputFeatureChannels:weights.conv_2.inputFeatureChannels
                             outputFeatureChannels:weights.conv_2.outputFeatureChannels
                                       strideWidth:weights.conv_2.strideWidth
                                      strideHeight:weights.conv_2.strideHeight
                                      paddingWidth:weights.conv_2.paddingWidth
                                     paddingHeight:weights.conv_2.paddingHeight
                                           weights:weights.conv_2.weights
                                            biases:weights.conv_2.biases
                                             label:weights.conv_2.label
                                     updateWeights:weights.conv_2.updateWeights
                                            device:dev
                                         cmd_queue:cmd_q];

    relu_2 = [MPSCNNNeuronReLUNNode nodeWithSource: [conv_2 resultImage]];

    conv_3 = [TCMPSLayerHelper createConvolutional:[relu_2 resultImage]
                                       kernelWidth:weights.conv_3.kernelWidth
                                      kernelHeight:weights.conv_3.kernelHeight
                              inputFeatureChannels:weights.conv_3.inputFeatureChannels
                             outputFeatureChannels:weights.conv_3.outputFeatureChannels
                                       strideWidth:weights.conv_3.strideWidth
                                      strideHeight:weights.conv_3.strideHeight
                                      paddingWidth:weights.conv_3.paddingWidth
                                     paddingHeight:weights.conv_3.paddingHeight
                                           weights:weights.conv_3.weights
                                            biases:weights.conv_3.biases
                                             label:weights.conv_3.label
                                     updateWeights:weights.conv_3.updateWeights
                                            device:dev
                                         cmd_queue:cmd_q];

    relu_3 = [MPSCNNNeuronReLUNNode nodeWithSource: [conv_3 resultImage]];

    pooling = [[MPSCNNPoolingAverageNode alloc] initWithSource:[relu_3 resultImage]
                                                   kernelWidth:weights.pooling.kernelSize
                                                  kernelHeight:weights.pooling.kernelSize 
                                               strideInPixelsX:weights.pooling.strideSize
                                               strideInPixelsY:weights.pooling.strideSize];

    m_feature = [relu_3 resultImage];
    m_output = [pooling resultImage];

    return self;  
  }
}

- (MPSNNImageNode * _Nullable) forwardPass {
  return m_output;
}

- (MPSNNImageNode * _Nullable) backwardPass:(MPSNNImageNode * _Nonnull)inputNode {
  MPSNNGradientFilterNode* pooling_grad = [pooling gradientFilterWithSource: inputNode];
  MPSNNGradientFilterNode* relu_3_grad = [relu_3 gradientFilterWithSource: [pooling_grad resultImage]];
  MPSNNGradientFilterNode* conv_3_grad = [conv_3 gradientFilterWithSource: [relu_3_grad resultImage]];
  MPSNNGradientFilterNode* relu_2_grad = [relu_2 gradientFilterWithSource: [conv_3_grad resultImage]];
  MPSNNGradientFilterNode* conv_2_grad = [conv_2 gradientFilterWithSource: [relu_2_grad resultImage]];
  MPSNNGradientFilterNode* relu_1_grad = [relu_1 gradientFilterWithSource: [conv_2_grad resultImage]];
  MPSNNGradientFilterNode* conv_1_grad = [conv_1 gradientFilterWithSource: [relu_1_grad resultImage]];
  
  return [conv_1_grad resultImage];
}

@end
