import os
os.environ["TF_USE_LEGACY_KERAS"] = "1"

import tensorflow as tf
import numpy as np

import larq as lq

model = tf.keras.models.load_model("weights/bnn_model.h5")

dense_layers = [model.layers[1], model.layers[3], model.layers[5]]

for n, layer in enumerate(dense_layers, start = 1):
    kernel = layer.get_weights()[0]  

    w_pm1 = np.where(kernel >= 0, 1, -1).astype(np.int8)

    np.save(f"weights/layer{n}_weights.npy", w_pm1)

    print(f"layer {n}: float kernel {kernel.shape}  ->  binarized {w_pm1.shape} of +/-1")

    print(f"   neuron 0, first 16 weights: {w_pm1[:16, 0]}")
import numpy as np
import os

W1 = np.load("weights/layer1_weights.npy")        # (784, 256) of +/-1
W2 = np.load("weights/layer2_weights.npy")        # (256, 256)
W3 = np.load("weights/layer3_weights.npy")        # (256, 10)
T1 = np.load("weights/layer1_threshold.npy")      # (256,) integers
T2 = np.load("weights/layer2_threshold.npy")      # (256,) integers

# Where the hardware-readable files go.
os.makedirs("weights/hw", exist_ok=True)

def to_bits(col):
    return "".join("1" if v == 1 else "0" for v in col[::-1])

def write_weights(W, path):
    with open(path, "w") as f:
        for j in range (W.shape[1]):
            f.write(to_bits(W[:,j]) + "\n") #one line = one neurons weight bits
    print(f"wrote {path}: {W.shape[1]} neurons x {W.shape[0]} bits each")



write_weights(W1, "weights/hw/layer1_weights.mem")
write_weights(W2, "weights/hw/layer2_weights.mem")
write_weights(W3, "weights/hw/layer3_weights.mem")

def write_thresholds(T, path):
    with open(path, "w") as f:
        for t in T:
            f.write(f"{int(t):x}\n")         # integer -> lowercase hex, one per line
    print(f"wrote {path}: {len(T)} thresholds")

write_thresholds(T1, "weights/hw/layer1_threshold.hex")
write_thresholds(T2, "weights/hw/layer2_threshold.hex")


#check, reading bit files back confirming match.
def read_bits_back(path, n_in, n_out):
    with open(path) as f:
        lines = [ln.strip() for ln in f if ln.strip()]
    assert len(lines) == n_out, f"{path}: expected {n_out} lines, got {len(lines)}"

    #make the +-1 matrix again but with bits
    cols = []
    for ln in lines:
        assert len(ln) == n_in, f"{path}: line length {len(ln)} != {n_in}"
        cols.append([1 if c == "1" else -1 for c in ln[::-1]])
    return np.array(cols).T 

W1_back = read_bits_back("weights/hw/layer1_weights.mem", 784, 256)
assert np.array_equal(W1_back, W1), "ROUND-TRIP FAILED: layer1 bits != original!"
print("\nRound-trip check passed: layer1 bits decode back to the exact +/-1 weights.")
import os
os.environ["TF_USE_LEGACY_KERAS"] = "1"
import tensorflow as tf
import numpy as np


W1 = np.load("weights/layer1_weights.npy")
W2 = np.load("weights/layer2_weights.npy")
W3 = np.load("weights/layer3_weights.npy")
T1 = np.load("weights/layer1_threshold.npy")
T2 = np.load("weights/layer2_threshold.npy")



(_, _), (test_images, test_labels) = tf.keras.datasets.mnist.load_data()
IDX = 0
img = (test_images[IDX] / 127.5) - 1.0        
true_label = test_labels[IDX]

x = np.where(img.flatten() >= 0, 1, -1)         

def bin_layer(x, W, T):
    total = x @ W
    popcount = (total + W.shape[0]) // 2
    return np.where(popcount >= T, 1, -1)

h1 = bin_layer(x,  W1, T1)        
h2 = bin_layer(h1, W2, T2)       

scores = h2 @ W3                  
prediction = int(np.argmax(scores))

os.makedirs("weights/hw", exist_ok=True)
bits = "".join("1" if v == 1 else "0" for v in x[::-1])   # reverse: input 0 -> bit 0
with open("weights/hw/test_image.mem", "w") as f:
    f.write(bits + "\n")


print(f"Test image index {IDX}, true label = {true_label}")
print(f"prediction = {prediction}")
print(f"10 output scores   = {scores}")
print(f"Layer1 first 8 outputs (+1/-1) = {h1[:8]}")
print(f"Wrote weights/hw/test_image.mem ({len(bits)} bits)")
import os
os.environ["TF_USE_LEGACY_KERAS"] = "1"
import tensorflow as tf
import numpy as np

W1 = np.load("weights/layer1_weights.npy");  T1 = np.load("weights/layer1_threshold.npy")
W2 = np.load("weights/layer2_weights.npy");  T2 = np.load("weights/layer2_threshold.npy")
W3 = np.load("weights/layer3_weights.npy")

(_, _), (test_images, test_labels) = tf.keras.datasets.mnist.load_data()

N = 20                                    
imgs = (test_images[:N] / 127.5) - 1.0    

def bin_layer(x, W, T):
    total = x @ W
    popcount = (total + W.shape[0]) // 2
    return np.where(popcount >= T, 1, -1)

def predict(img):
    x  = np.where(img.flatten() >= 0, 1, -1)
    h1 = bin_layer(x,  W1, T1)
    h2 = bin_layer(h1, W2, T2)
    return int(np.argmax(h2 @ W3))

os.makedirs("weights/hw", exist_ok=True)

with open("weights/hw/batch_images.mem", "w") as f:
    for i in range(N):
        x = np.where(imgs[i].flatten() >= 0, 1, -1)
        bits = "".join("1" if v == 1 else "0" for v in x[::-1])  
        f.write(bits + "\n")


preds = [predict(imgs[i]) for i in range(N)]
with open("weights/hw/batch_oracle.txt", "w") as f:
    for p in preds:
        f.write(f"{p}\n")


truth = test_labels[:N]
acc = np.mean(np.array(preds) == truth) * 100
print(f"Exported {N} images to weights/hw/batch_images.mem")
print(f"Model predictions: {preds}")
print(f"True labels:        {list(truth)}")
print(f"Model accuracy on these {N}: {acc:.1f}%")
