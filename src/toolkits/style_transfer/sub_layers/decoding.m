#include <toolkits/style_transfer/sub_layers/decoding.h>

@implementation Decoding

- (id _Nonnull) initWithParameters:(NSString * _Nullable)name
                         inputNode:(MPSNNImageNode * _Nonnull)inputNode
                            device:(id<MTLDevice> _Nonnull)dev
                         cmd_queue:(id<MTLCommandQueue> _Nonnull)cmd_q
                       initWeights:(struct DecodingWeights) weights {
  @autoreleasepool {
    self = [super init];
    return self;
  }
}

- (MPSNNImageNode * _Nullable) forwardPass {
  return nil;
}

- (MPSNNImageNode * _Nullable) backwardPass:(MPSNNImageNode * _Nonnull) inputNode {
  return nil;
}

- (MPSCNNNeuronReLU * _Nullable) finalNode {
  return nil;
}

@end