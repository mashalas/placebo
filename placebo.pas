PROGRAM placebo;

uses
    SysUtils, //UpperCase, GetEnvironmentVariable
    crt;

const
    CONFIG_EXTENSION:string = '.cfg';

var
    ConfigShortName: string;
    ConfigFullName: string;

Procedure help();
Begin
    writeln('Print predefined messages from the configuration file and terminate the program with the return code specified in the first line of the configuration file');
    {writeln('The name of the configuration file matches the name of the executable file (without .exe on windows), but has the .cfg extension. The configuration file is searched in the  following locations:');

current catalog;
directory with the executable file
directory specified by the environment variable TMP
directory specified by the environment variable TEMP
the file specified by the PLACEBO_CONFIG environment variable. In this case, the name of the configuration file can be any, and not formed by adding the cfg extension to the name of the executable file.
In the configuration file, the number with the program shutdown code should be written on the first line. The following lines contain the messages displayed on the screen. To output a string to the error stream <STDERR>, the string must begin with the sequence “stderr:” (the case does not matter, you do not need to write quotes). Similarly, you can force output to <STDOUT> later if the line begins with the sequence “stdout:" .}
End;


Function ReadConfig(filename: string): LongInt;
const
    STREAM_STDOUT:byte = 1;
    STREAM_STDERR:byte = 2;
    STREAM_DEFAULT:byte = 3;
var
    s: string;
    f: TextFile;
    RetCode: LongInt;
    LinesCount: word;
    Stream: byte;

procedure WriteToStream(stream: byte; s: string);
begin
    if stream = STREAM_STDOUT then
        write(stdout, s)
    else if stream = STREAM_STDERR then
        write(stderr, s)
    else
        write(s);
end;

procedure WriteEOL(stream: byte);
begin
    if stream = STREAM_STDOUT then
        writeln(stdout)
    else if stream = STREAM_STDERR then
        writeln(stderr)
    else
        writeln();
end;

Begin
    //writeln('Reading config from ' + filename);
    LinesCount := 0;
    AssignFile(f, filename);
    reset(f);
    Stream := STREAM_DEFAULT;
    while not(eof(f)) do
    begin
        Inc(LinesCount);
        readln(f, s);
        if LinesCount = 1 then
        begin
            //Первая строка с кодом возврата
            RetCode := StrToInt(s);
            continue;
        end;
        //вторая и последующие строки, которые надо вывести на экран
        if LinesCount > 2 then
        begin
            //перенос строки после вывода предыдущей строки
            WriteEOL(Stream);
        end;
        Stream := STREAM_DEFAULT;
        if length(s) >= 7 then
        begin
            //stderr msg
            //1234567890
            if UpperCase(copy(s, 1, 7)) = 'STDOUT:' then
            begin
                //выводить строку в <STDOUT>
                Stream := STREAM_STDOUT;
                s := copy(s, 8, length(s)-7);
            end;
            if UpperCase(copy(s, 1, 7)) = 'STDERR:' then
            begin
                //выводить строку в <STDERR>
                Stream := STREAM_STDERR;
                s := copy(s, 8, length(s)-7);
            end;
        end;
        WriteToStream(Stream, s);
    end;
    Exit(RetCode);
End;

BEGIN
    //Textrec(Output).FlushFunc:=nil;

    //Получить короткое имя конфигурационного файла
    ConfigShortName := ExtractFileName(ParamStr(0));
    if UpperCase(Copy(ConfigShortName, Length(ConfigShortName)-3, 4)) = '.EXE' then
        ConfigShortName := Copy(ConfigShortName, 1, Length(ConfigShortName)-4);
    ConfigShortName := ConfigShortName + CONFIG_EXTENSION;

    //Проверить наличие конфигурационного файла в текущем каталоге
    ConfigFullName := ConfigShortName;
    if FileExists(ConfigFullName) then
    begin
        ExitCode := ReadConfig(ConfigFullName);
        Halt(ExitCode);
    end;

    //Проверить наличие конфигурационного файла в одном каталоге с программой
    ConfigFullName := ConcatPaths([ExtractFileDir(ParamStr(0)), ConfigShortName]);
    if FileExists(ConfigFullName) then
    begin
        ExitCode := ReadConfig(ConfigFullName);
        Halt(ExitCode);
    end;

    //Проверить наличие конфигурационного файла в переменной среды TMP
    ConfigFullName := GetEnvironmentVariable('TMP');
    if Length(ConfigFullName) > 0 then
    begin
        //переменная среды задана
        ConfigFullName := ConcatPaths([ConfigFullName, ConfigShortName]);
        if FileExists(ConfigFullName) then
        begin
            ExitCode := ReadConfig(ConfigFullName);
            Halt(ExitCode);
        end;
    end;

    //Проверить наличие конфигурационного файла в переменной среды TMP
    ConfigFullName := GetEnvironmentVariable('TEMP');
    if Length(ConfigFullName) > 0 then
    begin
        //переменная среды задана
        ConfigFullName := ConcatPaths([ConfigFullName, ConfigShortName]);
        if FileExists(ConfigFullName) then
        begin
            ExitCode := ReadConfig(ConfigFullName);
            Halt(ExitCode);
        end;
    end;

    //Проверить наличие конфигурационного файла в переменной среды PLACEBO_CONFIG
    ConfigFullName := GetEnvironmentVariable('PLACEBO_CONFIG');
    if Length(ConfigFullName) > 0 then
    begin
        //переменная среды задана
        if FileExists(ConfigFullName) then
        begin
            ExitCode := ReadConfig(ConfigFullName);
            Halt(ExitCode);
        end;
    end;

END.
