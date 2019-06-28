#include <toolkits/style_transfer/vgg_16.h>
#include <ml/neural_net/mps_layer_helper.h>

@implementation VGG16Model

- (id _Nonnull) initWithParameters:(NSString * _Nullable)name
                         inputNode:(MPSNNImageNode * _Nonnull)inputNode
                            device:(id<MTLDevice> _Nonnull)dev
                         cmd_queue:(id<MTLCommandQueue> _Nonnull)cmd_q
                       initWeights:(struct Vgg16Weights)weights {
  @autoreleasepool {
    self = [super init];

    block_1 = [[Block1 alloc] initWithParameters:@"vvg16_block_1"
                                       inputNode:inputNode
                                          device:dev
                                       cmd_queue:cmd_q
                                     initWeights:weights.block_1];

    block_2 = [[Block1 alloc] initWithParameters:@"vvg16_block_2"
                                       inputNode:[block_1 forwardPass]
                                          device:dev
                                       cmd_queue:cmd_q
                                     initWeights:weights.block_2];



    block_3 = [[Block2 alloc] initWithParameters:@"vvg16_block_3"
                                       inputNode:[block_2 forwardPass]
                                          device:dev
                                       cmd_queue:cmd_q
                                     initWeights:weights.block_3];

    block_4 = [[Block2 alloc] initWithParameters:@"vvg16_block_4"
                                       inputNode:[block_3 forwardPass]
                                          device:dev
                                       cmd_queue:cmd_q
                                     initWeights:weights.block_4];

    m_output = [block_4 forwardPass];

    return self;
  }
}

- (MPSNNImageNode * _Nullable) forwardPass {
  return m_output;
}

- (MPSNNImageNode * _Nonnull) firstRELU {
  return [block_1 feature];
}

- (MPSNNImageNode * _Nonnull) secondRELU {
  return [block_2 feature];
}

- (MPSNNImageNode * _Nonnull) thirdRELU {
  return [block_3 feature];
}

- (MPSNNImageNode * _Nonnull) fourthRELU {
  return [block_4 feature];
}

- (MPSNNImageNode * _Nullable) backwardPass:(MPSNNImageNode * _Nonnull) inputNode {
  MPSNNImageNode* block_4_img = [block_4 backwardPass: inputNode];
  MPSNNImageNode* block_3_img = [block_3 backwardPass: block_4_img];
  MPSNNImageNode* block_2_img = [block_2 backwardPass: block_3_img];
  MPSNNImageNode* block_1_img = [block_1 backwardPass: block_2_img];
  
  return block_1_img;
}

@end