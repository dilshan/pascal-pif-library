program piflibtest;

{$mode objfpc}{$H+}

uses
  Interfaces, Forms, GuiTestRunner, fpcunittestrunner, tstpifoperations;

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TGuiTestRunner, TestRunner);
  Application.Run;
end.

