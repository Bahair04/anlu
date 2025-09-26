/************************************************************\
**	Copyright (c) 2012-2025 Anlogic Inc.
**	All Right Reserved.
\************************************************************/
/************************************************************\
**	Build time: Sep 26 2025 10:51:44
**	TD version	:	6.2.168116
************************************************************/
module ChipWatcher_0
(
  input   [7:0]                 probe0,
  input   [0:0]                 probe1,
  input   [15:0]                probe2,
  input   [24:0]                probe3,
  input   [1:0]                 probe4,
  input   [7:0]                 probe5,
  input   [24:0]                probe6,
  input   [9:0]                 probe7,
  input   [0:0]                 probe8,
  input   [0:0]                 probe9,
  input   [15:0]                probe10,
  input                         clk
);

  ChipWatcher_7244eeadc913  ChipWatcher_7244eeadc913_Inst
  (
      .probe0(probe0),
      .probe1(probe1),
      .probe2(probe2),
      .probe3(probe3),
      .probe4(probe4),
      .probe5(probe5),
      .probe6(probe6),
      .probe7(probe7),
      .probe8(probe8),
      .probe9(probe9),
      .probe10(probe10),
      .clk(clk)
  );
endmodule
