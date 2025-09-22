/************************************************************\
**	Copyright (c) 2012-2025 Anlogic Inc.
**	All Right Reserved.
\************************************************************/
/************************************************************\
**	Build time: Sep 15 2025 22:09:34
**	TD version	:	6.2.168116
************************************************************/
module ChipWatcher_uidbuf
(
  input   [0:0]                 probe0,
  input   [0:0]                 probe1,
  input   [0:0]                 probe2,
  input   [15:0]                probe3,
  input                         clk
);

  ChipWatcher_c3b5d90bce19  ChipWatcher_c3b5d90bce19_Inst
  (
      .probe0(probe0),
      .probe1(probe1),
      .probe2(probe2),
      .probe3(probe3),
      .clk(clk)
  );
endmodule
