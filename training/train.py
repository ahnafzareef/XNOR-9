inputs  = [ +1, -1, +1, +1, -1 ]
weights = [ +1, +1, +1, -1, -1 ]

N = len(inputs)  # number of inputs (must equal number of weights)

dot = 0
for i in range(N):
    dot += inputs[i] * weights[i]       # accumulate the products
print("dot product (multiply-and-sum):", dot)

agreements = 0
for i in range(N):
    if inputs[i] == weights[i]:         # comparison is the XNOR
        agreements += 1                 # counting these up is the popcount
print("agreements (the popcount):", agreements)

total = 2 * agreements - N
print("2 * popcount - N:", total)

threshold = 1
output = +1 if total >= threshold else -1
print("neuron output:", output)

def neuron(inputs, weights, threshold):
    N = len(inputs)                         # number of inputs this neuron sees
    agreements = 0                          # the popcount: how many inputs match
    for i in range(N):
        if inputs[i] == weights[i]:         # XNOR
            agreements += 1                 # count the agreement
    total = 2 * agreements - N             
    return +1 if total >= threshold else -1 

inputs = [ +1, -1, +1, +1, -1 ]
weight_matrix = [
    [ +1, +1, +1, -1, -1 ],                
    [ +1, -1, +1, +1, -1 ],                
    [ -1, +1, -1, -1, +1 ],                
]

thresholds = [ 1, 1, 1 ]    

layer_output = []                           
for j in range(len(weight_matrix)):         
    out = neuron(inputs, weight_matrix[j], thresholds[j])
    layer_output.append(out)                
    print(f"neuron {j}: output = {out}")    

print("layer output:", layer_output)
def neuron(inputs, weights, threshold):
    N = len(inputs)                        
    agreements = 0                          
    for i in range(N):
        if inputs[i] == weights[i]:         
            agreements += 1
    total = 2 * agreements - N              # identity: 2*popcount - N
    return +1 if total >= threshold else -1

def layer(inputs, weight_matrix, thresholds):
    outputs = []                            
    for j in range(len(weight_matrix)):     # loop over each neuron j
        out = neuron(inputs, weight_matrix[j], thresholds[j])
        outputs.append(out)
    return outputs  

network_input = [ +1, -1, +1, +1, -1 ] 

weights_L1 = [
    [ +1, +1, +1, -1, -1 ],                # neuron 0
    [ +1, -1, +1, +1, -1 ],                # neuron 1 
    [ -1, +1, -1, -1, +1 ],                # neuron 2 
]

thresholds_L1 = [ 1, 1, 1 ]

weights_L2 = [
    [ +1, +1, -1 ],                        # neuron 0
    [ -1, -1, +1 ],                        # neuron 1
]

thresholds_L2 = [ 1, 1 ]


hidden = layer(network_input, weights_L1, thresholds_L1)  
print("layer 1 output (hidden):", hidden)

output = layer(hidden, weights_L2, thresholds_L2)          
print("layer 2 output (final): ", output)
import os
os.environ["TF_USE_LEGACY_KERAS"] = "1"


import tensorflow as tf

(train_images, train_labels), (test_images, test_labels) = tf.keras.datasets.mnist.load_data()

print("train_images shape:", train_images.shape)   # expect (60000, 28, 28)
print("train_labels shape:", train_labels.shape)   # expect (60000,)
print("test_images shape: ", test_images.shape)    # expect (10000, 28, 28)

img   = train_images[0]    # a single 28x28 grid of pixel values 0-255
label = train_labels[0]    # the correct digit for that image
print("\nThis image is labeled:", label)

print("\nThe digit (each '#' is ink, blank is background):\n")
for row in img:                          # img has 28 rows
    line = ""
    for pixel in row:                    # each row has 28 pixels (0-255)
        line += "#" if pixel > 128 else " "   # 128 = halfway; bright->#, dark->blank
    print(line)
import os
os.environ["TF_USE_LEGACY_KERAS"] = "1"

import tensorflow as tf
import numpy as np 


(train_images, train_labels), _ = tf.keras.datasets.mnist.load_data()

img   = train_images[0]       # 28x28 grid, values 0-255
label = train_labels[0]
print("Label:", label)

binarized = np.where(img > 128, 1, -1)    # 28x28 grid of +1 / -1

print("binarized shape:", binarized.shape)   # still (28, 28) for now

print("\nBinarized digit (+1 -> '#', -1 -> blank):\n")
for row in binarized:
    line = ""
    for value in row:
        line += "#" if value == 1 else " "   # +1 is ink, -1 is blank
    print(line)

flat = binarized.flatten()
print("\nflattened shape:", flat.shape)   # expect (784,)
print("first 20 values:", flat[:20])      # a peek: a mix of +1 and -1
import os
os.environ["TF_USE_LEGACY_KERAS"] = "1"

import tensorflow as tf
import larq as lq    

# A dict so we don't repeat these three lines on each layer.
quant_settings = dict(
    input_quantizer="ste_sign",     # binarize this layer's INPUTS to +/-1
    kernel_quantizer="ste_sign",    # binarize this layer's WEIGHTS to +/-1
    kernel_constraint="weight_clip" # keep weights in [-1,1] during training so binarizing stays sane
)

model = tf.keras.Sequential([

    #turn the 28x28 image into a 784. 
    tf.keras.layers.Flatten(input_shape=(28,28)),

    #first hidden layer: 256 neurons, gets 784 inputs, produces 256 outputs
    lq.layers.QuantDense(256, use_bias=False, **quant_settings),
    tf.keras.layers.BatchNormalization(scale=False), 
    
    #second hidden: 256, reads 256
    lq.layers.QuantDense(256, use_bias=False, **quant_settings),
    tf.keras.layers.BatchNormalization(scale=False),
    
    #output layer: 10 neurons, reads 256, produces 10 outputs
    lq.layers.QuantDense(10, use_bias=False, **quant_settings),

    tf.keras.layers.Activation("softmax"),
])

#print
lq.models.summary(model)
import os
os.environ["TF_USE_LEGACY_KERAS"] = "1"

import tensorflow as tf
import larq as lq

(train_images, train_labels), (test_images, test_labels) = tf.keras.datasets.mnist.load_data()

#map pixel values from 0-255 to -1 and +1
train_images = (train_images / 127.5)  -1
test_images  = (test_images  / 127.5)  -1

quant_settings = dict(
    input_quantizer="ste_sign",     # binarize this layer's INPUTS to +/-1
    kernel_quantizer="ste_sign",    # binarize this layer's WEIGHTS to +/-1
    kernel_constraint="weight_clip" # keep weights in [-1,1] during training so binarizing stays sane
)

model = tf.keras.Sequential([

    tf.keras.layers.Flatten(input_shape=(28,28)),
    lq.layers.QuantDense(256, use_bias=False, **quant_settings),
    tf.keras.layers.BatchNormalization(scale=False),

    lq.layers.QuantDense(256, use_bias=False, **quant_settings),
    tf.keras.layers.BatchNormalization(scale=False),

    lq.layers.QuantDense(10, use_bias=False, **quant_settings),
    tf.keras.layers.Activation("softmax"),

])

model.compile(
    optimizer="adam",
    loss="sparse_categorical_crossentropy",
    metrics=["accuracy"],
)

model.fit(

    train_images, train_labels,
    batch_size=64,
    epochs=6,
    validation_data=(test_images,test_labels), #accuracy check on unseen images
)

#final score on the 10k images the model didnt see
loss, acc = model.evaluate(test_images, test_labels)
print(f"\nFinal test accuracy: {acc*100:.2f}%")

model.save("weights/bnn_model.h5")
print("\nModel saved to weights/bnn_model.h5")
