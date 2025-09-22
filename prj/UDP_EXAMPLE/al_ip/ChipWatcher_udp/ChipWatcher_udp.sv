/************************************************************\
**	Copyright (c) 2012-2025 Anlogic Inc.
**	All Right Reserved.
\************************************************************/
/************************************************************\
**	Build time: Sep 14 2025 15:13:12
**	TD version	:	6.2.168116
************************************************************/
module ChipWatcher_udp
(
  input   [0:0]                 probe0,
  input   [7:0]                 probe1,
  input   [15:0]                probe2,
  input                         clk
);

  ChipWatcher_0ab6c5a2fd02  ChipWatcher_0ab6c5a2fd02_Inst
  (
      .probe0(probe0),
      .probe1(probe1),
      .probe2(probe2),
      .clk(clk)
  );
endmodule
