--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);

package body A0B.STM32F401.USART.Generic_USART2_SPI is

   pragma Warnings
     (Off, "ll instances of ""*"" will have the same external name");
   --  It is by design to prevent multiple instanses of the package.

   procedure USART2_Handler
     with Export, Convention => C, External_Name => "USART2_Handler";

   --------------------
   -- USART2_Handler --
   --------------------

   procedure USART2_Handler is
   begin
      USART2_SPI.On_Interrupt;
   end USART2_Handler;

end A0B.STM32F401.USART.Generic_USART2_SPI;
