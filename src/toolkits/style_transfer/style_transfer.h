#ifndef TURI_STYLE_TRANSFER_INFERENCE_H_
#define TURI_STYLE_TRANSFER_INFERENCE_H_

#import <Accelerate/Accelerate.h>
#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>

#include <toolkits/style_transfer/transformer.h>
#include <toolkits/style_transfer/pre_processing.h>
#include <toolkits/style_transfer/vgg_16.h>

#include <toolkits/style_transfer/utils.h>

API_AVAILABLE(macos(10.15))
@interface StyleTransfer : NSObject {
  MPSNNImageNode *contentNode;
  MPSNNImageNode *contentScaleNode;
  MPSNNImageNode *contenMeanNode;

  MPSNNImageNode *styleNode;
  MPSNNImageNode *styleScaleNode;
  MPSNNImageNode *styleMeanNode;

  TransformerModel *model;

  PreProcessing *content_pre_process;
  PreProcessing *style_pre_process_loss;
  PreProcessing *content_pre_process_loss;

  VGG16Model *content_vgg;
  VGG16Model *style_vgg_loss;
  VGG16Model *content_vgg_loss;

  MPSNNGraph *inference_graph;
  MPSNNGraph *training_graph;
}

- (id _Nonnull) initWithParameters:(NSString * _Nullable)name
                            device:(id<MTLDevice> _Nonnull)dev
               transformer_weights:(struct TransformerWeights)transformer_weights
                       vgg_weights:(struct Vgg16Weights)vgg_weights
                         cmd_queue:(id<MTLCommandQueue> _Nonnull)cmd_q;

- (MPSImage * _Nullable) forward:(MPSImage * _Nonnull)image;

@end

#endif