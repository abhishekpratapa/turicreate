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
  return nil;
}

- (MPSNNImageNode * _Nullable) backwardPass:(MPSNNImageNode * _Nonnull) inputNode {
  return nil;
}

@end