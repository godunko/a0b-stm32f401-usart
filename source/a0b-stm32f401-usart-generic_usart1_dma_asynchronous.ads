--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  STM32F401 USART1 in Asynchronous (UART) mode

pragma Restrictions (No_Elaboration_Code);

with A0B.STM32F401.DMA.DMA2.Stream7;

generic
   Receive_Stream : not null access A0B.STM32F401.DMA.DMA_Stream'Class;
   TX_Pin         : not null access A0B.STM32F401.GPIO.GPIO_Line'Class;
   RX_Pin         : not null access A0B.STM32F401.GPIO.GPIO_Line'Class;

package A0B.STM32F401.USART.Generic_USART1_DMA_Asynchronous
  with Preelaborate
is

   pragma Elaborate_Body;

   USART1_Asynchronous : aliased USART_Asynchronous_Device
     (Peripheral       => A0B.STM32F401.SVD.USART.USART1_Periph'Access,
      Controller       => 1,
      Interrupt        => A0B.STM32F401.USART1,
      Transmit_Stream  => A0B.STM32F401.DMA.DMA2.Stream7.DMA2_Stream7'Access,
      Transmit_Channel => 4,
      Receive_Stream   => Receive_Stream,
      Receive_Channel  => 4,
      TX_Pin           => TX_Pin,
      TX_Line          => A0B.STM32F401.USART1_TX,
      RX_Pin           => RX_Pin,
      RX_Line          => A0B.STM32F401.USART1_RX);

end A0B.STM32F401.USART.Generic_USART1_DMA_Asynchronous;
