// Core Temp reader for Icinga
// Copyright (c) 2015 Michal Krowicki
// https://krowicki.pl
 
 
program SMCoreTempDelphiReader;
 
{$MODE Delphi}
 
{$APPTYPE CONSOLE}
 
uses
  Windows,
  SysUtils,
  GetCoreTempInfoDelphi in 'GetCoreTempInfoDelphi.pas';
 
var
  Data: CORE_TEMP_SHARED_DATA;
  CPU, Core, Index: Cardinal;
  Degree: Char;
  OutputMsg, param, CPUPerfName, CorePerfName: String;
  Temp: Single;
  FreqMin, FreqMax, VoltMin, VoltMax, TempWarn, TempCrit, LoadWarn, LoadCrit, i, ExitStatus: Integer;
  FreqMinStr, FreqMaxStr, VoltMinStr, VoltMaxStr, TempWarnStr, TempCritStr, LoadWarnStr, LoadCritStr: String;
const
  STATUS_OK = 0;
  STATUS_WARN = 1;
  STATUS_CRIT = 2;
  STATUS_UNKNOWN = 3;
 
function StringToOem(const Str: string): AnsiString;
begin
  Result := AnsiString(Str);
  if Length(Result) > 0 then
    CharToOemA(PAnsiChar(Result), PAnsiChar(Result));
end;
 
function StringToCaseSelect
  (Selector : string;
   CaseList: array of string): Integer;
   var cnt: integer;
   begin
   Result:=-1;
   for cnt:=0 to Length(CaseList)-1 do
   begin
   if CompareText(Selector, CaseList[cnt]) = 0 then
   begin
      Result:=cnt;
      Break;
    end;
  end;
end;
 
function GetParam(const Param: string): string;
var parpos: integer;
begin
     parpos:=Pos(':',Param);
     if(parpos > 1) then
         Result:=LeftStr(param,parpos)
     else
         Result:=Param;
end;
 
function GetParamValue(const Param: string): string;
var parpos: integer;
begin
     parpos:=Pos(':',Param);
     if(parpos > 1) then
     begin
//       writeln('param="' + param + '" parpos="' + IntToStr(parpos) + '" ' + RightStr(param,Length(Param)-parpos));
       Result:=RightStr(param,Length(Param)-parpos);
     end
     else
         Result:='';
end;
 
{
STATUS_OK = 0;
STATUS_WARN = 1;
STATUS_CRIT = 2;
STATUS_UNKNOWN = 3;
}
 
 
begin
  ExitStatus := STATUS_UNKNOWN;
  try
    if fnGetCoreTempInfo(Data) then
    begin
      FreqMin := 0;
      FreqMax := 0;
      VoltMin := 0;
      VoltMax := 0;
      TempWarn := 0;
      TempCrit := 0;
      LoadWarn := 0;
      LoadCrit := 0;
 
      for i := 0 to ParamCount do
      begin
           param :=ParamStr(i);
           case StringToCaseSelect(GetParam(param),['-fmin:','-fmax:','-vmin:','-vmax:','-twarn:','-tcrit:','-lwarn:','-lcrit:']) of
                0:FreqMin := StrToInt(GetParamValue(param));
                1:FreqMax := StrToInt(GetParamValue(param));
                2:VoltMin := StrToInt(GetParamValue(param));
                3:VoltMax := StrToInt(GetParamValue(param));
                4:TempWarn := StrToInt(GetParamValue(param));
                5:TempCrit := StrToInt(GetParamValue(param));
                6:LoadWarn := StrToInt(GetParamValue(param));
                7:LoadCrit := StrToInt(GetParamValue(param));
           end;
      end;
 
      if(FreqMin > 0) then FreqMinStr := IntToStr(FreqMin);
      if(FreqMax > 0) then FreqMaxStr := IntToStr(FreqMax);
      if(VoltMin > 0) then VoltMinStr := IntToStr(VoltMin);
      if(VoltMax > 0) then VoltMaxStr := IntToStr(VoltMax);
      if(TempWarn > 0) then TempWarnStr := IntToStr(TempWarn);
      if(TempCrit > 0) then TempCritStr := IntToStr(TempCrit);
      if(LoadWarn > 0) then LoadWarnStr := IntToStr(LoadWarn);
      if(LoadCrit > 0) then LoadCritStr := IntToStr(LoadCrit);
 
 
 
      OutputMsg := 'Processor ' + Data.sCPUName;
      if Data.uiCPUCnt > 1 then
        OutputMsg += IntToStr(Data.uiCPUCnt)+' CPUs, '
      else
        OutputMsg += IntToStr(Data.uiCPUCnt)+' CPU, ';
 
      if (Data.uiCoreCnt > 1) then
        OutputMsg += IntToStr(Data.uiCoreCnt) + ' cores, '
      else
        OutputMsg += IntToStr(Data.uiCoreCnt)+' core, ';
      OutputMsg += 'speed ' + FloatToStrF(Data.fCPUSpeed, ffFixed, 7, 0) + 'MHz';
      OutputMsg += ' (' + FloatToStrF(Data.fFSBSpeed, ffFixed, 7, 0) + '*' + FloatToStrF(Data.fMultipier, ffFixed, 7, 1) + '), ';
      OutputMsg += 'VID ' + FloatToStrF(Data.fVID, ffFixed, 7, 2) + 'V';
 
      if Data.ucFahrenheit then
        Degree := 'F'
      else
        Degree := 'C';
      for CPU := 0 to Data.uiCPUCnt - 1 do
      begin
        for Core := 0 to Data.uiCoreCnt - 1 do
        begin
          Index := (CPU * Data.uiCoreCnt) + Core;
          if Data.ucDeltaToTjMax then
            Temp := Data.uiTjMax[CPU] - Data.fTemp[Index]
          else
            Temp := Data.fTemp[Index];
//          Writeln;
          OutputMsg += ', CPU ' + IntToStr(CPU) + ' Core ' + IntToStr(Core) + ': ';
          OutputMsg += 'Temperature = ' + FloatToStrF(Temp, ffFixed, 7, 0) + Degree + ' ';
          OutputMsg += 'Load = ' + IntToStr(Data.uiLoad[Index]) + '%';
        end;
      end;
      OutputMsg += '|';
      for CPU := 0 to Data.uiCPUCnt - 1 do
      begin
 
        CPUPerfName := ('''CPU' + IntToStr(CPU));
        OutputMsg += CPUPerfName + 'Freq''=' + StringReplace(FloatToStrF(Data.fCPUSpeed, ffFixed, 7, 0),',','.',[]) + 'MHz' + ';;;' + FreqMinStr + ';' + FreqMaxStr + ' ';
        OutputMsg += CPUPerfName + 'Voltage''=' + StringReplace(FloatToStrF(Data.fVID, ffFixed, 7, 2),',','.',[]) + 'V' + ';;;' + VoltMinStr + ';' + VoltMaxStr + ' ';
 
        for Core := 0 to Data.uiCoreCnt - 1 do
        begin
          Index := (CPU * Data.uiCoreCnt) + Core;
          if Data.ucDeltaToTjMax then
            Temp := Data.uiTjMax[CPU] - Data.fTemp[Index]
          else
            Temp := Data.fTemp[Index];
 
            CorePerfName := (CPUPerfName + 'Core' + IntToStr(Core));
            OutputMsg += CorePerfName + 'Temp''=' + FloatToStrF(Temp, ffFixed, 7, 0) + Degree + ';';
            OutputMsg += TempWarnStr + ';' + TempCritStr + ';0;' + IntToStr(Data.uiTjMax[CPU]) + ' ';
            OutputMsg += CorePerfName + 'Load''=' + IntToStr(Data.uiLoad[Index]) + '%' + ';';
            OutputMsg += LoadWarnStr + ';' + LoadCritStr + ';0;100 ';
 
 
            if (((TempCrit > 0) and (LoadCrit > 0)) and ((Round(Temp) >= TempCrit) or (Data.uiLoad[Index] >= LoadCrit))) then
                 ExitStatus := STATUS_CRIT
            else if (((TempWarn > 0) and (LoadWarn > 0)) and ((Round(Temp) >= TempWarn) or (Data.uiLoad[Index] >= LoadWarn)) and (ExitStatus <> STATUS_CRIT)) then
                 ExitStatus := STATUS_WARN
            else
                 ExitStatus := STATUS_OK;
 
        end
      end;
    end
    else
    begin
      OutputMsg:='Error: Core Temp''s shared memory could not be read';
      OutputMsg+='Reason: ' + StringToOem(SysErrorMessage(GetLastError));
    end;
  except
    on E: Exception do
    begin
         OutputMsg := E.Classname + ': '+ E.Message;
    end;
  end;
  case ExitStatus of
       STATUS_OK:      Write('OK : ');
       STATUS_WARN:    Write('Warning : ');
       STATUS_CRIT:    Write('Critical : ');
       STATUS_UNKNOWN: Write('Unknown : ');
  end;
  Writeln(OutputMsg);
 
  System.ExitCode := ExitStatus;
 
end.
