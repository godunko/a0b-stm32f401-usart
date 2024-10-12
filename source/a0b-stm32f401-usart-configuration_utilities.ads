--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  STM32F401 USART configuration utilities

pragma Restrictions (No_Elaboration_Code);

package A0B.STM32F401.USART.Configuration_Utilities
  with Preelaborate
is

   procedure Compute_Configuration
     (Peripheral_Frequency : A0B.Types.Unsigned_32;
      Baud_Rate            : A0B.Types.Unsigned_32;
      Configuration        : out Asynchronous_Configuration);
   --  Compute USART configuration

end A0B.STM32F401.USART.Configuration_Utilities;
