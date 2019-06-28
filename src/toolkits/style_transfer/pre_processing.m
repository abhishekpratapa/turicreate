#include <toolkits/style_transfer/pre_processing.h>
#include <ml/neural_net/mps_layer_helper.h>

@implementation PreProcessing

- (id _Nonnull) initWithParameters:(NSString * _Nullable)name
                         inputNode:(MPSNNImageNode * _Nonnull)inputNode
                         scaleNode:(MPSNNImageNode * _Nonnull)scaleNode
                          meanNode:(MPSNNImageNode * _Nonnull)meanNode
                            device:(id<MTLDevice> _Nonnull)dev
                         cmd_queue:(id<MTLCommandQueue> _Nonnull)cmd_q {
  @autoreleasepool {
    self = [super init];

    MPSNNMultiplicationNode *multiplicationNode = [MPSNNMultiplicationNode nodeWithLeftSource:inputNode
                                                                                  rightSource:scaleNode];

    MPSNNSubtractionNode *subtractionNode = [MPSNNSubtractionNode nodeWithLeftSource:[multiplicationNode resultImage]
                                                                         rightSource:meanNode];

    m_output = [subtractionNode resultImage];
    return self;
  }
}

- (MPSNNImageNode * _Nullable) forwardPass {
  return m_output;
}

- (MPSNNImageNode * _Nullable) backwardPass:(MPSNNImageNode * _Nonnull)inputNode {
  return Nil;
}

@end