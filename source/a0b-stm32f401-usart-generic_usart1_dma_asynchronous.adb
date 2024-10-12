--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

package body A0B.STM32F401.USART.Generic_USART1_DMA_Asynchronous is

   pragma Warnings
     (Off, "ll instances of ""*"" will have the same external name");
   --  It is by design to prevent multiple instanses of the package.

   procedure USART1_Handler
     with Export, Convention => C, External_Name => "USART1_Handler";

   --------------------
   -- USART1_Handler --
   --------------------

   procedure USART1_Handler is
   begin
      USART1_Asynchronous.On_Interrupt;
   end USART1_Handler;

end A0B.STM32F401.USART.Generic_USART1_DMA_Asynchronous;
