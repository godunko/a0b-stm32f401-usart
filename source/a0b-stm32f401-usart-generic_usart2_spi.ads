--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  STM32F401 USART2 in SPI mode

pragma Restrictions (No_Elaboration_Code);

generic
   MOSI_Pin : not null access A0B.STM32F401.GPIO.GPIO_Line'Class;
   MISO_Pin : not null access A0B.STM32F401.GPIO.GPIO_Line'Class;
   SCK_Pin  : not null access A0B.STM32F401.GPIO.GPIO_Line'Class;
   NSS_Pin  : not null access A0B.STM32F401.GPIO.GPIO_Line'Class;

package A0B.STM32F401.USART.Generic_USART2_SPI
  with Preelaborate
is

   pragma Elaborate_Body;

   USART2_SPI : aliased USART_SPI_Device
     (Peripheral => A0B.STM32F401.SVD.USART.USART2_Periph'Access,
      Controller => 2,
      Interrupt  => A0B.STM32F401.USART2,
      MOSI_Pin   => MOSI_Pin,
      MOSI_Line  => A0B.STM32F401.USART2_TX,
      MISO_Pin   => MISO_Pin,
      MISO_Line  => A0B.STM32F401.USART2_RX,
      SCK_Pin    => SCK_Pin,
      SCK_Line   => A0B.STM32F401.USART2_CK,
      NSS_Pin    => NSS_Pin);

end A0B.STM32F401.USART.Generic_USART2_SPI;
