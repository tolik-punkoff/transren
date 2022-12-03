program transren;

//{$mode objfpc}{$H+}
//{$codepage UTF8}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, CustApp, FileUtil, regexpr, fgl, Keyboard
  { you can add units after this };

type

  { TTransren }

  TTransren = class(TCustomApplication)
  protected
    procedure DoRun; override;
  private
    NoToAll:boolean;
    YesToAll:boolean;
  public
    procedure WriteHelp; virtual;
    function Translit(Str:UnicodeString):UnicodeString; virtual;
    function Ask(FilePath:UnicodeString):boolean; virtual;
    procedure ReverseList(var List: TStringList); virtual;
  end;

  {TFPGMap}

  TDictTrans=class(specialize TFPGMap<UnicodeString, UnicodeString>);

{ TTransren }

procedure TTransren.DoRun;
var
  Mask, StartDir:string;
  IncludeSubdirs, TranslitSubdirs, TranslitFiles, FindOnly:boolean;
  i:LongInt;
  lstFiles, lstDirs:TStringList;
  sOnlyFileName, sTransFileName, sNewFileName:UnicodeString;
  sOnlyDirName, sTransDirName, sNewDirName:UnicodeString;
  ctrFoundFiles, ctrRenamedFiles, ctrErrFiles:longint;
  ctrFoundDirs, ctrRenamedDirs, ctrErrDirs, ctrSkipDirs:longint;

begin
   //init variables
   Mask:=''; StartDir:='';
   IncludeSubdirs:=false; TranslitSubdirs:=false; TranslitFiles:=false;
   i:=0;
   sOnlyFileName:=''; sTransFileName:=''; sNewFileName:='';
   sOnlyDirName:=''; sTransDirName:=''; sNewDirName:='';
   ctrFoundFiles:=0; ctrRenamedFiles:=0; ctrErrFiles:=0;
   ctrFoundDirs:=0; ctrRenamedDirs:=0; ctrErrDirs:=0; ctrSkipDirs:=0;
   YesToAll:=false; NoToAll:=false;

  // check if no parameters
  if ParamCount=0 then begin
    WriteHelp;
    Terminate;
    Exit;
  end;

  // parse parameters
  //print help and exit
  if HasOption('h', '') then begin
    WriteHelp;
    Terminate;
    Exit;
  end;
  //mask
  if HasOption('m','') then begin
     Mask:=GetOptionValue('m','');
     if Mask = '' then begin
        WriteHelp;
        Terminate;
        Exit;
     end;
     TranslitFiles:=true;
  end;
  //start directory
  StartDir:=GetOptionValue('d','');
  if StartDir='' then begin
     StartDir:=GetCurrentDir();
  end;
  //Include subdirs
  IncludeSubdirs:=HasOption('s','');
  //Translit subdirs names
  TranslitSubdirs:=HasOption('t','');
  //Find only
  FindOnly:=HasOption('f','');

  //If not -m <mask> and not -t - no main parameters
  if (not TranslitFiles) and (not TranslitSubdirs) then begin
     WriteHelp;
     Terminate;
     Exit;
  end;

  //check if start directory exist
  if not DirectoryExists(StartDir) then begin
     WriteLn('Directory ', StartDir, ' not exists!');
     Terminate;
     Exit;
  end;

  if TranslitFiles then begin
     WriteLn('Translit files...');
     //Find files by mask
     lstFiles:=TStringList.Create;
     try
       FindAllFiles(lstFiles,StartDir,Mask,IncludeSubdirs);
       i:=0;
       //cycle for find files
       while i < lstFiles.Count do begin
         sOnlyFileName := ExtractFileName(lstFiles[i]); //get file name
         sTransFileName := Translit (sOnlyFileName); //get translit file name

         //check if file name transliterated
         if sOnlyFileName <> sTransFileName then begin
            inc(ctrFoundFiles); //include counter for found files
            //name transliterated, rename file
            sNewFileName := ExtractFilePath(lstFiles[i]) + sTransFileName;
            Write(lstFiles[i], ' --> ', sTransFileName, ' --> ');
            if FindOnly then begin
              WriteLn('FO.');
              inc(i);
              Continue;
            end;
            if FileExists(sNewFileName) then begin //check if file already exist
              WriteLn('Exists!');
              if Ask(ExtractFileName(sNewFileName)) then begin //ask for replace
                //Rename file
                DeleteFile(sNewFileName); //delete old renamed file
                if RenameFile(lstFiles[i],sNewFileName) then begin
                   WriteLn(' OK.');
                   inc(ctrRenamedFiles); //inc counter for renamed files
                end
                else begin
                   WriteLn(' ERROR!');
                   inc(ctrErrFiles); //inc counter for errors
                end;
              end;
            end
            else begin
                //Rename file
                if RenameFile(lstFiles[i],sNewFileName) then begin
                   WriteLn('OK.');
                   inc(ctrRenamedFiles); //inc counter for renamed files
                end
                else begin
                   Writeln ('Rename error!');
                   inc(ctrErrFiles); //inc counter for errors
                end;
            end;
         end;
          inc (i); //include counter
      end;
    finally
         lstFiles.Free();
    end;
  end; //end translit files

  //Translit subdirs
  if TranslitSubdirs then begin
    WriteLn();
    WriteLn('Translit directories...');
    lstDirs:=TStringList.Create;
     try
       FindAllDirectories(lstDirs,StartDir,IncludeSubdirs);
       i:=0;
       ReverseList(lstDirs);
       //cycle for find dirs
       while i < lstDirs.Count do begin
         sOnlyDirName := ExtractFileName(lstDirs[i]); //get dir name
         sTransDirName := Translit (sOnlyDirName); //get translit dir name

         //check if dir name transliterated
         if sOnlyDirName <> sTransDirName then begin
            inc(ctrFoundDirs); //include counter for found dirs
            //name transliterated, rename dir
            sNewDirName := ExtractFilePath(lstDirs[i]) + sTransDirName;
            Write(lstDirs[i], ' --> ', sTransDirName, ' --> ');
            if FindOnly then begin
              WriteLn('FO.');
              inc(i);
              Continue;
            end;
            if DirectoryExists(sNewDirName) then begin //check if dir exist
               //Skip if directory exist
               WriteLn('Skip.');
               inc(ctrSkipDirs); //inc counter for skipping dirs
            end
            else begin
                //Rename dirs
                if RenameFile(lstDirs[i],sNewDirName) then begin
                   WriteLn('OK.');
                   inc(ctrRenamedDirs); //inc counter for renamed dirs
                end
                else begin
                   Writeln ('Rename error!');
                   inc(ctrErrDirs); //inc counter for errors
                end;
            end;

         end;
         inc(i); //include counter
       end;
     finally
       lstFiles.Free();
     end;
  end; //end translit subdirs

  //write counters
  if TranslitFiles then begin
    WriteLn();
    WriteLn('Found files: ', ctrFoundFiles);
    WriteLn('Renamed files: ', ctrRenamedFiles);
    WriteLn('Error files: ', ctrErrFiles);
  end;
  if TranslitSubdirs then begin
    if TranslitFiles then WriteLn();
    WriteLn('Found directories: ', ctrFoundDirs);
    WriteLn('Renamed directories: ', ctrRenamedDirs);
    WriteLn('Skip directories: ', ctrSkipDirs);
    WriteLn('Error directories: ', ctrErrDirs);
  end;

  //ReadLn();
  // stop program loop
  Terminate;
end;
function TTransren.Ask(FilePath:UnicodeString):boolean;
var K: TKeyEvent;
    KS:String;
begin
   if (YesToAll) then exit(true);
   if (NoToAll) then begin Writeln(); exit(false); end;

   Write ('File ', FilePath, ' is exists! Replace file?',
      '[Yes/No/yes to All/nO to all]');
   InitKeyBoard;
   while true do begin
      K:=GetKeyEvent;
      K:=TranslateKeyEvent(K);
      KS:=KeyEventToString(K);

      if (KS='Y') or (KS='y') then begin
                                      DoneKeyBoard;
                                      exit(true);
                                   end;
      if (KS='N') or (KS='n') then begin
                                      DoneKeyBoard;
                                      Writeln();
                                      exit(false);
                                   end;
      if (KS='A') or (KS='a') then begin //yes to all
                                      DoneKeyBoard;
                                      YesToAll:=true;
                                      exit(true);
                                   end;
      if (KS='O') or (KS='o') then begin
                                      DoneKeyBoard;
                                      Writeln();
                                      NoToAll:=true;
                                      exit(false);
                                   end;
    end;

  DoneKeyBoard;
  exit(true);
end;
procedure TTransren.WriteHelp;
begin
  Writeln ('Tanslit Renamer (transren), this program replace russian letters');
  Writeln ('in file and dirs names to latin letters');
  Writeln ('v 0.0.1b (L) ChaosSoftware 2022.');
  WriteLn();
  Writeln('Usage: ',ExtractFileName(ExeName), ' <-h>|<-m <mask> or/and <-t>>',
     '[-d] [-s]');
  WriteLn('-h - this help');
  WriteLn('-m <mask> - file mask for search. Parameter must be!');
  WriteLn('-t - translit subdirectories names');
  WriteLn('[-d] <directory> - start directory. If not, use current dir.');
  WriteLn('[-s] - include subdirs');
  WriteLn('[-f] - find only (no rename files/dirs)');
  WriteLn();
  WriteLn('e.g.:');
  WriteLn(ExtractFileName(ExeName), ' -m *.html',' - translit *.html in current',
     ' directory');
  WriteLn(ExtractFileName(ExeName), ' -t *.html',' - translit subdirs in current',
     ' directory');
  WriteLn(ExtractFileName(ExeName), ' -m *.html -s ',' - translit *.html in ',
     'current directory and subdirs');
  WriteLn(ExtractFileName(ExeName), ' -m *.* -s -t',' - translit all files in ',
     'current directory and translit all subdirs');
  WriteLn(ExtractFileName(ExeName), ' -m *.html -d D:\DOC\ ',
     ' - translit *.html files in D:\DOC');
end;

function TTransren.Translit(Str:UnicodeString):UnicodeString;
var Regex:TRegExpr;
    Dict:TDictTrans;
    Ch,oStr,oTrans:UnicodeString;
    I:LongInt;
begin
     Regex:=TRegExpr.Create;
     Regex.Expression:='[А-Я]|[а-я]|\s';
     if not Regex.Exec(Str) then begin
       exit(Str);
     end;
     Dict:=TDictTrans.Create;
     Dict.Add(' ','_');
     Dict.Add('А','A'); Dict.Add('а','a');
     Dict.Add('Б','B'); Dict.Add('б','b');
     Dict.Add('В','V'); Dict.Add('в','v');
     Dict.Add('Г','G'); Dict.Add('г','g');
     Dict.Add('Д','D'); Dict.Add('д','d');
     Dict.Add('Е','E'); Dict.Add('е','e');
     Dict.Add('Ё','YO'); Dict.Add('ё','yo');
     Dict.Add('Ж','ZH'); Dict.Add('ж','zh');
     Dict.Add('З','Z'); Dict.Add('з','z');
     Dict.Add('И','I'); Dict.Add('и','i');
     Dict.Add('Й','J'); Dict.Add('й','j');
     Dict.Add('К','K'); Dict.Add('к','k');
     Dict.Add('Л','L'); Dict.Add('л','l');
     Dict.Add('М','M'); Dict.Add('м','m');
     Dict.Add('Н','N'); Dict.Add('н','n');
     Dict.Add('О','O'); Dict.Add('о','o');
     Dict.Add('П','P'); Dict.Add('п','p');
     Dict.Add('Р','R'); Dict.Add('р','r');
     Dict.Add('С','S'); Dict.Add('с','s');
     Dict.Add('Т','T'); Dict.Add('т','t');
     Dict.Add('У','U'); Dict.Add('у','u');
     Dict.Add('Ф','F'); Dict.Add('ф','f');
     Dict.Add('Х','KH'); Dict.Add('х','kh');
     Dict.Add('Ц','TS'); Dict.Add('ц','ts');
     Dict.Add('Ч','CH'); Dict.Add('ч','ch');
     Dict.Add('Ш','SH'); Dict.Add('ш','sh');
     Dict.Add('Щ','SHCH'); Dict.Add('щ','shch');
     Dict.Add('Ъ','_'); Dict.Add('ъ','_');
     Dict.Add('Ы','Y'); Dict.Add('ы','y');
     Dict.Add('Ь','_'); Dict.Add('ь','_');
     Dict.Add('Э','JE'); Dict.Add('э','je');
     Dict.Add('Ю','JU'); Dict.Add('ю','ju');
     Dict.Add('Я','JA'); Dict.Add('я','ja');

     Ch:=''; oStr:='';
     for I:=1 to Length(Str) do begin
       Ch:=Copy(Str,I,1);
       if Dict.TryGetData(Ch, oTrans) then begin
          oStr:=oStr+oTrans; //russkaya bukva - transliteriruem
       end
       else begin
         oStr:=oStr+Ch; //nerusskaya bukva, ostavlaem v pokoe
       end;
     end;
     Dict.Free;
     exit(oStr);
end;
procedure TTransren.ReverseList(var List: TStringList);
var
   TmpList: TStringList;
   I: Integer;
begin
   TmpList := TStringList.Create;
   for I := List.Count -1 DownTo 0 do
      TmpList.Append(List[I]);
   List.Assign(TmpList);
   TmpList.Free;
end;

var
  Application: TTransren;

begin
  Application:=TTransren.Create(nil);
  Application.Title:='transren';
  Application.Run;
  Application.Free;
end.

