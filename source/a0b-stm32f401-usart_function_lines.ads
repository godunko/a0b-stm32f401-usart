--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  STM32F401 USART function line descriptors

pragma Restrictions (No_Elaboration_Code);
pragma Ada_2022;

package A0B.STM32F401.USART_Function_Lines
  with Preelaborate
is

   USART1_CTS : aliased constant Function_Line_Descriptor;
   USART1_RTS : aliased constant Function_Line_Descriptor;
   USART1_TX  : aliased constant Function_Line_Descriptor;
   USART1_RX  : aliased constant Function_Line_Descriptor;
   USART1_CK  : aliased constant Function_Line_Descriptor;
   USART2_CTS : aliased constant Function_Line_Descriptor;
   USART2_RTS : aliased constant Function_Line_Descriptor;
   USART2_TX  : aliased constant Function_Line_Descriptor;
   USART2_RX  : aliased constant Function_Line_Descriptor;
   USART2_CK  : aliased constant Function_Line_Descriptor;
   USART6_TX  : aliased constant Function_Line_Descriptor;
   USART6_RX  : aliased constant Function_Line_Descriptor;
   USART6_CK  : aliased constant Function_Line_Descriptor;

private

   USART1_CTS : aliased constant Function_Line_Descriptor :=
     [(A, 11, 7)];
   USART1_RTS : aliased constant Function_Line_Descriptor :=
     [(A, 12, 7)];
   USART1_TX  : aliased constant Function_Line_Descriptor :=
     [(A, 9, 7), (B, 6, 7)];
   USART1_RX  : aliased constant Function_Line_Descriptor :=
     [(A, 10, 7), (B, 7, 7)];
   USART1_CK  : aliased constant Function_Line_Descriptor :=
     [(A, 8, 7)];
   USART2_CTS : aliased constant Function_Line_Descriptor :=
     [(A, 0, 7), (D, 3, 7)];
   USART2_RTS : aliased constant Function_Line_Descriptor :=
     [(A, 1, 7), (D, 4, 7)];
   USART2_TX  : aliased constant Function_Line_Descriptor :=
     [(A, 2, 7), (D, 5, 7)];
   USART2_RX  : aliased constant Function_Line_Descriptor :=
     [(A, 3, 7), (D, 6, 7)];
   USART2_CK  : aliased constant Function_Line_Descriptor :=
     [(A, 4, 7), (D, 7, 7)];
   USART6_TX  : aliased constant Function_Line_Descriptor :=
     [(A, 11, 8), (C, 6, 8)];
   USART6_RX  : aliased constant Function_Line_Descriptor :=
     [(A, 12, 8), (C, 7, 8)];
   USART6_CK  : aliased constant Function_Line_Descriptor :=
     [(C, 8, 8)];

end A0B.STM32F401.USART_Function_Lines;
