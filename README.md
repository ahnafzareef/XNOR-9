# XNOR-9

Draw a digit on your phone and a tiny FPGA guesses what number it is. The neural network doesn't run on a computer or a processor — it runs as actual logic on the chip.

## Why I made it

I wanted to understand quantization: how you shrink a neural network by storing its numbers in fewer bits. So I went to the extreme and built a network where every weight is a single bit, just +1 or -1.

The cool part is what that does to the hardware. Normally a neural network multiplies a lot of decimal numbers, which is slow and expensive. But when everything is just +1 or -1, multiplying turns into one simple question: do the two values match? That's one logic gate. So the whole network can run on the plain logic of a cheap FPGA, with no special math hardware.

I used a small, cheap FPGA on purpose. Fitting a real network onto a tiny chip means you actually have to understand where everything goes.

## How it works

Three parts:

- **Python** trains the network and shrinks every weight down to one bit (about 32x smaller).
- **The FPGA** does the actual digit recognition, in logic.
- **An ESP32** hosts a little web page so you can draw on your phone, then sends the drawing to the FPGA and shows the answer.

The phone talks to the ESP32 over Wi-Fi, and the ESP32 talks to the FPGA over a UART link I wrote myself in Verilog.

## What's in here

```
training/   Python: train the network and export the weights
fpga/       Verilog: the part that does the recognition
firmware/   ESP32 code: the web page and the link to the FPGA
weights/    The weight files the FPGA reads
```

## Running it

Train and export the weights:
```
cd training
pip install -r requirements.txt
python train.py
python export_weights.py
python verify.py
```

Build the FPGA part with the Lushay Code extension and load it onto the Tang Nano 9K.

Flash the ESP32:
```
cd firmware
idf.py set-target esp32s3
idf.py build flash monitor
```

Then connect your phone to the `BNN_Demo` Wi-Fi and open `http://192.168.4.1`.

## How well it works

About 95% on MNIST. It's a small network, so it won't beat a big one, but the goal was efficient hardware, not the highest score. It guesses best when you draw big, centered, and thick.

## References

- Ertorer & Unsalan, *Binary Neural Network Implementation for Handwritten Digit Recognition on FPGA* — arXiv:2512.19304 (https://arxiv.org/pdf/2512.19304)
- https://www.sciencedirect.com/science/article/abs/pii/S0167926026000295
