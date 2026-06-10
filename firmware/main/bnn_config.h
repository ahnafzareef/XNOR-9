#ifndef BNN_CONFIG_H
#define BNN_CONFIG_H

// image dimensions
#define IMAGE_WIDTH 28
#define IMAGE_HEIGHT 28
#define IMAGE_PIXELS (IMAGE_WIDTH * IMAGE_HEIGHT)
#define IMG_PACKED_BYTES ((IMAGE_PIXELS + 7) / 8) //+7 for ceiling division
#define INK_THRESHOLD 127                       // threshold for binarizing pixel values

// UART LINKING INTO THE FPGA
#define FPGA_UART_PORT UART_NUM_1
#define FPGA_UART_TX_PIN 17
#define FPGA_UART_RX_PIN 18
#define FPGA_UART_BAUD_RATE 115200
#define FPGA_REPLY_TIMEOUT_MS 500 // max wait time

// WIFI ACCESS
#define AP_SSID "BNN_DRAW"
#define AP_PASSWORD "bnn12345"
#define AP_CHANNEL 1
#define AP_MAX_CONNECTIONS 4

#endif // BNN_CONFIG_H
