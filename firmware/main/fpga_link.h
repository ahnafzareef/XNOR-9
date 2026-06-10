#ifndef FPGA_LINK_H
#define FPGA_LINK_H

#include <stdint.h>
#include "esp_err.h"

// inst the uart
esp_err_t fpga_link_init(void);

esp_err_t fpga_link_classify(const uint8_t *p_image, int *out_digit);

esp_err_t fpga_link_loopback_test(void);

#endif // FPGA_LINK_H