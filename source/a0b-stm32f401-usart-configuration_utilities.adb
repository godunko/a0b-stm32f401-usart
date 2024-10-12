--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Restrictions (No_Elaboration_Code);
pragma Ada_2022;

package body A0B.STM32F401.USART.Configuration_Utilities is

   ---------------------------
   -- Compute_Configuration --
   ---------------------------

   procedure Compute_Configuration
     (Peripheral_Frequency : A0B.Types.Unsigned_32;
      Baud_Rate            : A0B.Types.Unsigned_32;
      Configuration        : out Asynchronous_Configuration)
   is
      use type A0B.Types.Unsigned_32;

      Div : A0B.Types.Unsigned_32 := 2 * Peripheral_Frequency / Baud_Rate;

   begin
      Configuration.Oversampling := Oversampling_16;

      case Configuration.Oversampling is
         when Oversampling_8 =>
            Div := @ / 2;
            Div := @ / 2 + @ mod 2;

            Configuration.DIV_Fraction :=
              A0B.STM32F401.SVD.USART.BRR_DIV_Fraction_Field (Div mod 8);
            Configuration.DIV_Mantissa :=
              A0B.STM32F401.SVD.USART.BRR_DIV_Mantissa_Field (Div / 8);

         when Oversampling_16 =>
            Div := @ / 2 + @ mod 2;

            Configuration.DIV_Fraction :=
              A0B.STM32F401.SVD.USART.BRR_DIV_Fraction_Field (Div mod 16);
            Configuration.DIV_Mantissa :=
              A0B.STM32F401.SVD.USART.BRR_DIV_Mantissa_Field (Div / 16);
      end case;
   end Compute_Configuration;

end A0B.STM32F401.USART.Configuration_Utilities;
