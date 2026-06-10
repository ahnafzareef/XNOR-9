import os
os.environ["TF_USE_LEGACY_KERAS"] = "1"   

import tensorflow as tf
import larq as lq

print("TensorFlow version:", tf.__version__)
print("Larq version:      ", lq.__version__)

x = tf.constant([1, 2, 3])
print("TF math check:", (x + x).numpy())
import os
os.environ["TF_USE_LEGACY_KERAS"] = "1"

import tensorflow as tf
import larq as lq
import numpy as np


custom_objects = {}
custom_objects.update(lq.layers.__dict__)
custom_objects.update(lq.quantizers.__dict__)
custom_objects.update(lq.constraints.__dict__)

model = tf.keras.models.load_model("weights/bnn_model.h5")

def fold_threshold(bn_layer, N):
    beta, mean, var = bn_layer.get_weights()
    eps = 1e-3
    theta = mean - beta*np.sqrt(var+eps)
    T = np.ceil((theta + N) / 2.0).astype(np.int32)
    return T
    #returns out T as one integer, we will do this in verilog

#layer stuff, each layer needs t for each neuron

#2 cus its input, then dense then batch, then dense then batch again which is 4
T1 = fold_threshold(model.layers[2], N = 784)  # input to layer 1 has 784 neurons
T2 = fold_threshold(model.layers[4], N = 256)  # input to layer 2 has 256 neurons

np.save("weights/layer1_threshold.npy", T1)
np.save("weights/layer2_threshold.npy", T2)

print("Saved thresholds. T1[:5] =", T1[:5], " T2[:5] =", T2[:5])

W1 = np.load("weights/layer1_weights.npy")       # (784, 256)
W2 = np.load("weights/layer2_weights.npy")       # (256, 256)
W3 = np.load("weights/layer3_weights.npy")      # (256, 10)
#so math time

def bin_layer(x, W, T):
    # multiplying and adding is just dot product

    total = x @ W #dot product same as (agreements - disagreements) and 2*p - N

    popcount = (total + W.shape[0]) // 2  # convert from [-N, N] to [0, N] and divide by 2 to get number of +1s

    return np.where(popcount >= T, 1, -1)

def predict(img):
    x = np.where(img.flatten() >= 0, 1, -1)
    h1 = bin_layer(x, W1, T1)
    h2 = bin_layer(h1, W2, T2)
    scores = h2 @ W3 #last layer is sfotmax dont wan between -1 and 1
    return np.argmax(scores)    #pick the class with the highest score


(_, _), (test_images, test_labels) = tf.keras.datasets.mnist.load_data()
test_images = (test_images / 127.5) - 1.0      # same preprocessing as training

keras_pred = np.argmax(model.predict(test_images, verbose=0), axis=1)
numpy_pred = np.array([predict(img) for img in test_images])

agreement = np.mean(keras_pred == numpy_pred) * 100
accuracy  = np.mean(numpy_pred == test_labels) * 100
print(f"\nNumPy-vs-Keras agreement: {agreement:.2f}%")
print(f"NumPy accuracy on test set: {accuracy:.2f}%")

import os
os.environ["TF_USE_LEGACY_KERAS"] = "1"

import tensorflow as tf
import larq as lq
import numpy as np

model = tf.keras.models.load_model("weights/bnn_model.h5")

# Walk every layer and print its type, name, and the shapes of its parameters.
for i, layer in enumerate(model.layers):
    print(f"\n[{i}] {layer.__class__.__name__}  (name: {layer.name})")
    weights = layer.get_weights()          # list of numpy arrays this layer holds
    if not weights:
        print("    (no trainable parameters)")
    for w in weights:
        print("    param shape:", w.shape)
