# TuriCreate GPU: Neural Net
 
 The Mac GPU accleration in MPS is implemented in this directory. This README.md serves as an overview for the Graph API of the MPS

## Layers

 `mps_graph_layers.h` - is the file where the MPSGraph layers are defined. Use layer definitions from this file when creating your neuralNetwork graphs. Add layers to this file when those layers aren't present.

### Defined Layers

##### Forward Pass Layers
	- ReLUGraphLayer
	- ConvGraphLayer
	- BNGraphLayer
	- MaxPoolGraphLayer

##### Loss Layers
	- LossGraphLayer
	- YoloLossGraphLayer


