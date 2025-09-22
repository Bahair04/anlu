/************************************************************\
**	Copyright (c) 2012-2025 Anlogic Inc.
**	All Right Reserved.
\************************************************************/
/************************************************************\
**	Build time: Sep 14 2025 15:09:22
**	TD version	:	6.2.168116
************************************************************/
module ChipWatcher_0
(
  input   [15:0]                probe0,
  input   [15:0]                probe1,
  input   [0:0]                 probe2,
  input   [0:0]                 probe3,
  input                         clk
);

  ChipWatcher_7244eeadc913  ChipWatcher_7244eeadc913_Inst
  (
      .probe0(probe0),
      .probe1(probe1),
      .probe2(probe2),
      .probe3(probe3),
      .clk(clk)
  );
endmodule
