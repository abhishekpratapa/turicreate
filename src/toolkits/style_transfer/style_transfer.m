#include <toolkits/style_transfer/style_transfer.h>
#include <ml/neural_net/mps_layer_helper.h>
#include <ml/neural_net/mps_node_handle.h>

@implementation StyleTransfer

- (id _Nonnull) initWithParameters:(NSString * _Nullable)name
                            device:(id<MTLDevice> _Nonnull)dev
               transformer_weights:(struct TransformerWeights)transformer_weights
                       vgg_weights:(struct Vgg16Weights)vgg_weights
                         cmd_queue:(id<MTLCommandQueue> _Nonnull)cmd_q{
  @autoreleasepool {
    self = [super init];

    MPSCNNLossDescriptor *style_desc = [MPSCNNLossDescriptor cnnLossDescriptorWithType:MPSCNNLossTypeMeanSquaredError
                                                                         reductionType:MPSCNNReductionTypeMean];
    style_desc.weight = 0.5*0.0001*0.0001;

    MPSCNNLossDescriptor *content_desc = [MPSCNNLossDescriptor cnnLossDescriptorWithType:MPSCNNLossTypeMeanSquaredError
                                                                           reductionType:MPSCNNReductionTypeMean];
    content_desc.weight = 0.5*0.0001;


    contentNode = [MPSNNImageNode nodeWithHandle: [[TCMPSGraphNodeHandle alloc] initWithLabel:@"contentImage"]];
    contentScaleNode = [MPSNNImageNode nodeWithHandle: [[TCMPSGraphNodeHandle alloc] initWithLabel:@"contentScaleImage"]];
    contenMeanNode = [MPSNNImageNode nodeWithHandle: [[TCMPSGraphNodeHandle alloc] initWithLabel:@"contentMeanImage"]];

    styleNode = [MPSNNImageNode nodeWithHandle: [[TCMPSGraphNodeHandle alloc] initWithLabel:@"styleImage"]];
    styleScaleNode = [MPSNNImageNode nodeWithHandle: [[TCMPSGraphNodeHandle alloc] initWithLabel:@"styleScaleImage"]];
    styleMeanNode = [MPSNNImageNode nodeWithHandle: [[TCMPSGraphNodeHandle alloc] initWithLabel:@"styleMeanImage"]];

    model = [[TransformerModel alloc] initWithParameters:@"Transformer"
                                               inputNode:contentNode
                                                  device:dev
                                               cmd_queue:cmd_q
                                             initWeights:transformer_weights];

    content_pre_process = [[PreProcessing alloc] initWithParameters:@"Pre_Process_Content"
                                                          inputNode:[model forwardPass]
                                                          scaleNode:contentScaleNode
                                                           meanNode:contenMeanNode
                                                             device:dev
                                                          cmd_queue:cmd_q];


    content_vgg = [[VGG16Model alloc] initWithParameters:@"VGG_Content"
                                               inputNode:[content_pre_process forwardPass]
                                                  device:dev
                                               cmd_queue:cmd_q
                                             initWeights:vgg_weights];

    style_pre_process_loss = [[PreProcessing alloc] initWithParameters:@"Pre_Process_Style_Loss"
                                                             inputNode:styleNode
                                                             scaleNode:styleScaleNode
                                                              meanNode:styleMeanNode
                                                                device:dev
                                                             cmd_queue:cmd_q];

    style_vgg_loss = [[VGG16Model alloc] initWithParameters:@"VGG_Style_Loss"
                                                  inputNode:[style_pre_process_loss forwardPass]
                                                     device:dev
                                                  cmd_queue:cmd_q
                                                initWeights:vgg_weights];


    content_pre_process_loss = [[PreProcessing alloc] initWithParameters:@"Pre_Process_Content_Loss"
                                                               inputNode:contentNode
                                                               scaleNode:contentScaleNode
                                                                meanNode:contenMeanNode
                                                                  device:dev
                                                               cmd_queue:cmd_q];

    
    content_vgg_loss = [[VGG16Model alloc] initWithParameters:@"VGG_Content_Loss"
                                                    inputNode:[content_pre_process_loss forwardPass]
                                                       device:dev
                                                    cmd_queue:cmd_q
                                                  initWeights:vgg_weights];

    // TODO: Change to Image Size;
    int gram_scaling_1 = (256 * 256);
    int gram_scaling_2 = ((256/2) * (256/2));
    int gram_scaling_3 = ((256/4) * (256/4));
    int gram_scaling_4 = ((256/8) * (256/8));

    MPSNNGramMatrixCalculationNode *gram_matrix_style_loss_first_relu
      = [MPSNNGramMatrixCalculationNode nodeWithSource:[style_vgg_loss firstRELU]
                                                 alpha:(1.0/gram_scaling_1)];

    MPSNNGramMatrixCalculationNode *gram_matrix_content_vgg_first_relu
      = [MPSNNGramMatrixCalculationNode nodeWithSource:[content_vgg firstRELU]
                                                 alpha:(1.0/gram_scaling_1)];

    MPSNNForwardLossNode *style_loss_node_1 = [MPSNNForwardLossNode nodeWithSource:[gram_matrix_content_vgg_first_relu resultImage]
                                                                            labels:[gram_matrix_style_loss_first_relu resultImage]
                                                                    lossDescriptor:style_desc];



    MPSNNGramMatrixCalculationNode *gram_matrix_style_loss_second_relu
      = [MPSNNGramMatrixCalculationNode nodeWithSource:[style_vgg_loss secondRELU]
                                                 alpha:(1.0/gram_scaling_2)];

    MPSNNGramMatrixCalculationNode *gram_matrix_content_vgg_second_relu
      = [MPSNNGramMatrixCalculationNode nodeWithSource:[content_vgg secondRELU]
                                                 alpha:(1.0/gram_scaling_2)];

    MPSNNForwardLossNode *style_loss_node_2 = [MPSNNForwardLossNode nodeWithSource:[gram_matrix_content_vgg_second_relu resultImage]
                                                                            labels:[gram_matrix_style_loss_second_relu resultImage]
                                                                    lossDescriptor:style_desc];



    MPSNNGramMatrixCalculationNode *gram_matrix_style_loss_third_relu
      = [MPSNNGramMatrixCalculationNode nodeWithSource:[style_vgg_loss thirdRELU]
                                                 alpha:(1.0/gram_scaling_3)];

    MPSNNGramMatrixCalculationNode *gram_matrix_content_vgg_third_relu
      = [MPSNNGramMatrixCalculationNode nodeWithSource:[content_vgg thirdRELU]
                                                 alpha:(1.0/gram_scaling_3)];

    MPSNNForwardLossNode *style_loss_node_3 = [MPSNNForwardLossNode nodeWithSource:[gram_matrix_content_vgg_third_relu resultImage]
                                                                            labels:[gram_matrix_style_loss_third_relu resultImage]
                                                                    lossDescriptor:style_desc];



    MPSNNGramMatrixCalculationNode *gram_matrix_style_loss_fourth_relu
      = [MPSNNGramMatrixCalculationNode nodeWithSource:[style_vgg_loss fourthRELU]
                                                 alpha:(1.0/gram_scaling_4)];

    MPSNNGramMatrixCalculationNode *gram_matrix_content_vgg_fourth_relu
      = [MPSNNGramMatrixCalculationNode nodeWithSource:[content_vgg fourthRELU]
                                                 alpha:(1.0/gram_scaling_4)];

    MPSNNForwardLossNode *style_loss_node_4 = [MPSNNForwardLossNode nodeWithSource:[gram_matrix_content_vgg_fourth_relu resultImage]
                                                                            labels:[gram_matrix_style_loss_fourth_relu resultImage]
                                                                    lossDescriptor:style_desc];



    MPSNNForwardLossNode *content_loss_node = [MPSNNForwardLossNode nodeWithSource:[content_vgg thirdRELU]
                                                                            labels:[content_vgg_loss thirdRELU]
                                                                    lossDescriptor:content_desc];


    MPSNNAdditionNode* add_loss_1_1 = [MPSNNAdditionNode nodeWithSources:@[[style_loss_node_1 resultImage],
                                                                           [style_loss_node_2 resultImage]]];

    MPSNNAdditionNode* add_loss_1_2 = [MPSNNAdditionNode nodeWithSources:@[[style_loss_node_3 resultImage],
                                                                           [style_loss_node_4 resultImage]]];

    MPSNNAdditionNode* add_loss_1 = [MPSNNAdditionNode nodeWithSources:@[[add_loss_1_1 resultImage],
                                                                         [add_loss_1_2 resultImage]]];

    MPSNNAdditionNode* total_loss = [MPSNNAdditionNode nodeWithSources:@[[add_loss_1 resultImage],
                                                                         [content_loss_node resultImage]]];

    MPSNNInitialGradientNode *initial_gradient = [MPSNNInitialGradientNode nodeWithSource:[total_loss resultImage]];

    BOOL resultsAreNeeded[] = { YES, YES };

    NSArray<MPSNNFilterNode*>* lastNodes = [initial_gradient trainingGraphWithSourceGradient:[initial_gradient resultImage]
                                                                                 nodeHandler: nil];

    training_graph = [MPSNNGraph graphWithDevice: [cmd_q device]
                                    resultImages: @[lastNodes[0].resultImage, lastNodes[1].resultImage]
                                resultsAreNeeded: &resultsAreNeeded[0]];

    inference_graph = [MPSNNGraph graphWithDevice: [cmd_q device]
                                      resultImage: [model forwardPass]
                              resultImageIsNeeded:YES];

    training_graph.format = MPSImageFeatureChannelFormatFloat32;
    inference_graph.format = MPSImageFeatureChannelFormatFloat32;

    return self;
  }
}


- (MPSImage * _Nullable) forward:(MPSImage * _Nonnull)image {
  return Nil;
}

@end