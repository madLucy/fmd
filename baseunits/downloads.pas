{
        File: downloads.pas
        License: GPLv2
        This unit is part of Free Manga Downloader
}

unit downloads;

{$mode delphi}

interface

uses
  Classes, SysUtils, IniFiles, baseunit, data, fgl, zip;

type
  TDownloadManager = class;
  TTaskThreadContainer = class;
  TTaskThread = class;

  // this class will replace the old TDownloadThread
  TDownloadThread = class(TThread)
  protected
    // Get download link from URL
    function    GetLinkPageFromURL(const URL: String): Boolean;
    // Get number of download link from URL
    function    GetPageNumberFromURL(const URL: String): Boolean;
    // Download page - link from link list
    function    DownloadPage: Boolean;
    procedure   Execute; override;
    procedure   OnTag(tag: String);
    procedure   OnText(text: String);
  public
    checkStyle    : Cardinal;

    isTerminated,
    isSuspended   : Boolean;
    // ID of the site
    workPtr       : Cardinal;
    manager       : TTaskThread;
    parse         : TStringList;
    constructor Create;
    destructor  Destroy; override;
  end;

  TDownloadThreadList = TFPGList<TDownloadThread>;

  TTaskThread = class(TThread)
  protected
    procedure   CheckOut;
    procedure   Repaint;
    procedure   Execute; override;
    procedure   Compress;
    // show notification when download completed
    procedure   ShowBaloon;
  public
    isTerminated,
    isSuspended: Boolean;

    Flag: Cardinal;
    // container (for storing information)
    container  : TTaskThreadContainer;
    // download threads
    threads    : TDownloadThreadList;

    constructor Create;
    destructor  Destroy; override;
    procedure   Stop(const check: Boolean = TRUE);
  end;

  TTaskThreadContainer = class
    // task thread of this container
    thread : TTaskThread;
    // download manager
    manager: TDownloadManager;

    downloadInfo: TDownloadInfo;

    // current link index
    currentPageNumber,
    // current chapter index
    currentDownloadChapterPtr,
    activeThreadCount,
    Status     : Cardinal;
    workPtr    : Cardinal;
    mangaSiteID: Cardinal;
    pageNumber : Cardinal;

    chapterName,
    chapterLinks,
    pageContainerLinks,
    pageLinks  : TStringList;

    constructor Create;
    destructor  Destroy; override;
  end;

  TTaskThreadContainerList = TFPGList<TTaskThreadContainer>;

  TDownloadManager = class(TObject)
  private
  public
    isFinishTaskAccessed: Boolean;

    compress,
    // number of tasks
    retryConnect,
    // max. active tasks
    maxDLTasks,
    // max. download threads per task
    maxDLThreadsPerTask : Cardinal;
    // current chapterLinks which thread is processing
    containers          : TTaskThreadContainerList;

    ini                 : TIniFile;

   // downloadInfo        : array of TDownloadInfo;
    constructor Create;
    destructor  Destroy; override;

    procedure   Restore;
    procedure   Backup;

    // Add new task to the list
    procedure   AddTask;
    // Check and active previous work-in-progress tasks
    procedure   CheckAndActiveTaskAtStartup;
    // Check and active waiting tasks
    procedure   CheckAndActiveTask;
    // Check if we can active another wating task or not
    function    CanActiveTask: Boolean;
    // Active a stopped task
    procedure   ActiveTask(const taskID: Cardinal);
    // Stop a download/wait task
    procedure   StopTask(const taskID: Cardinal);
    // Stop all download/wait tasks
    procedure   StopAllTasks;
    // Stop all download task inside a task before terminate the program
    procedure   StopAllDownloadTasksForExit;
    // Mark the task as "Finished"
    procedure   FinishTask(const taskID: Cardinal);
    // Swap 2 tasks
    function    Swap(const id1, id2: Cardinal): Boolean;
    // move a task up
    function    MoveUp(const taskID: Cardinal): Boolean;
    // move a task down
    function    MoveDown(const taskID: Cardinal): Boolean;
    // Remove a task from list
    procedure   RemoveTask(const taskID: Cardinal);
    // Remove all finished tasks
    procedure   RemoveAllFinishedTasks;
  end;

implementation

uses mainunit, FastHTMLParser, HTMLUtil, SynaCode;

// ----- TDownloadThread -----

procedure   TDownloadThread.OnTag(tag: String);
begin
  parse.Add(tag);
end;

procedure   TDownloadThread.OnText(text: String);
begin
  parse.Add(text);
end;

constructor TDownloadThread.Create;
begin
  isTerminated:= FALSE;
  isSuspended := TRUE;
  FreeOnTerminate:= TRUE;
  inherited Create(FALSE);
end;

destructor  TDownloadThread.Destroy;
begin
  Dec(manager.container.activeThreadCount);
  isTerminated:= TRUE;
  inherited Destroy;
end;

procedure   TDownloadThread.Execute;
var
  i: Cardinal;
begin
  while isSuspended do
    Sleep(100);
  case checkStyle of
    // get page number, and prepare number of pagelinks for save links
    CS_GETPAGENUMBER:
      begin
        GetPageNumberFromURL(manager.container.chapterLinks.Strings[manager.container.currentDownloadChapterPtr]);
        // prepare 'space' for link updater
        for i:= 0 to manager.container.pageNumber-1 do
          manager.container.pageLinks.Add('W');
      end;
    // get page link
    CS_GETPAGELINK:
      begin
        GetLinkPageFromURL(manager.container.chapterLinks.Strings[manager.container.currentDownloadChapterPtr]);
      end;
    // download page
    CS_DOWNLOAD:
      begin
        DownloadPage;
      end;
  end;
  Terminate;
end;

function    TDownloadThread.GetPageNumberFromURL(const URL: String): Boolean;
var
  Parser: TjsFastHTMLParser;

  function GetAnimeAPageNumber: Boolean;
  var
    i: Cardinal;
    l: TStringList;
  begin
    l:= TStringList.Create;
    Result:= GetPage(TObject(l), ANIMEA_ROOT +
                                 StringReplace(URL, '.html', '', []) +
                                 '-page-1.html',
                                 manager.container.manager.retryConnect);
    for i:= 0 to l.Count-1 do
      if (Pos('Page 1 of ', l.Strings[i])<>0) then
      begin
        manager.container.pageNumber:= StrToInt(GetString(l.Strings[i], 'Page 1 of ', '<'));
        break;
      end;
    l.Free;
  end;

  function GetMangaHerePageNumber: Boolean;
  var
    i, j: Cardinal;
    l   : TStringList;
  begin
    l:= TStringList.Create;
    parse:= TStringList.Create;
    Result:= GetPage(TObject(l),
                     MANGAHERE_ROOT + URL,
                     manager.container.manager.retryConnect);
    Parser:= TjsFastHTMLParser.Create(PChar(l.Text));
    Parser.OnFoundTag := OnTag;
    Parser.OnFoundText:= OnText;
    Parser.Exec;
    Parser.Free;
    if parse.Count>0 then
    begin
      manager.container.pageNumber:= 0;
      for i:= 0 to parse.Count-1 do
      begin
        if GetTagName(parse.Strings[i]) = 'option' then
        begin
          j:= i;
          while GetTagName(parse.Strings[j]) = 'option' do
          begin
            Inc(manager.container.pageNumber);
            Inc(j, 4);
          end;
          break;
        end;
      end;
    end;
    parse.Free;
    l.Free;
  end;

  function GetMangaInnPageNumber: Boolean;
  var
    s   : String;
    i, j: Cardinal;
    l   : TStringList;
  begin
    l:= TStringList.Create;
    parse:= TStringList.Create;
    Result:= GetPage(TObject(l),
                     MANGAINN_ROOT + URL,
                     manager.container.manager.retryConnect);
    Parser:= TjsFastHTMLParser.Create(PChar(l.Text));
    Parser.OnFoundTag := OnTag;
    Parser.OnFoundText:= OnText;
    Parser.Exec;
    Parser.Free;
    if parse.Count>0 then
    begin
      manager.container.pageNumber:= 1;
      for i:= 0 to parse.Count-1 do
      begin
        if Pos('Previous', parse.Strings[i]) <> 0 then
         // if Pos('Page', parse.Strings[i+2]) <> 0 then
        begin
          j:= i+7;
          s:= parse.Strings[j];
          while GetTagName(parse.Strings[j]) = 'option' do
          begin
            Inc(manager.container.pageNumber);
            Inc(j, 3);
          end;
          break;
        end;
      end;
    end;
    parse.Free;
    l.Free;
  end;

  function GetOurMangaPageNumber: Boolean;
  // OurManga is a lot different than other site
  var
    isExtractpageContainerLinks: Boolean = FALSE;
    correctURL,
    s   : String;
    i, j: Cardinal;
    l   : TStringList;
  begin
    // pass 1: Find correct chapter
    l:= TStringList.Create;
    parse:= TStringList.Create;
    Result:= GetPage(TObject(l),
                     OURMANGA_ROOT + URL,
                     manager.container.manager.retryConnect);
    Parser:= TjsFastHTMLParser.Create(PChar(l.Text));
    Parser.OnFoundTag := OnTag;
    Parser.OnFoundText:= OnText;
    Parser.Exec;
    Parser.Free;
    if parse.Count>0 then
    begin
      manager.container.pageNumber:= 1;
      for i:= 0 to parse.Count-1 do
      begin
        if (GetTagName(parse.Strings[i]) = 'a') AND
           (Pos(OURMANGA_ROOT + URL, parse.Strings[i]) <> 0) then
          correctURL:= GetAttributeValue(GetTagAttribute(parse.Strings[i], 'href='));
      end;
    end;
    parse.Clear;
    l.Clear;

    // pass 2: Find number of pages

    Result:= GetPage(TObject(l),
                     correctURL,
                     manager.container.manager.retryConnect);
    manager.container.pageContainerLinks.Clear;
    Parser:= TjsFastHTMLParser.Create(PChar(l.Text));
    Parser.OnFoundTag := OnTag;
    Parser.OnFoundText:= OnText;
    Parser.Exec;
    Parser.Free;
    if parse.Count>0 then
    begin
      manager.container.pageNumber:= 0;
      for i:= 0 to parse.Count-1 do
      begin
        if NOT isExtractpageContainerLinks then
        begin
          if (GetTagName(parse.Strings[i]) = 'select') AND
             (GetAttributeValue(GetTagAttribute(parse.Strings[i], 'name=')) = 'page') then
            isExtractpageContainerLinks:= TRUE;
        end
        else
        begin
          if (GetTagName(parse.Strings[i]) = 'option') then
          begin
            manager.container.pageContainerLinks.Add(GetAttributeValue(GetTagAttribute(parse.Strings[i], 'value=')));
            Inc(manager.container.pageNumber);
          end
          else
          if Pos('</select>', parse.Strings[i])<>0 then
            break;
        end;
      end;
    end;
    parse.Free;
    l.Free;
  end;

  function GetBatotoPageNumber: Boolean;
  var
    s   : String;
    i, j: Cardinal;
    l   : TStringList;
  begin
    l:= TStringList.Create;
    parse:= TStringList.Create;
    Result:= GetPage(TObject(l),
                     BATOTO_ROOT + DecodeURL(URL) + '/1',
                     manager.container.manager.retryConnect);
    Parser:= TjsFastHTMLParser.Create(PChar(l.Text));
    Parser.OnFoundTag := OnTag;
    Parser.OnFoundText:= OnText;
    Parser.Exec;
    Parser.Free;
    parse.Add(BATOTO_ROOT + URL + '/1');
    parse.SaveToFile('ttt.txt');
    if parse.Count>0 then
    begin
      manager.container.pageNumber:= 1;
      for i:= 0 to parse.Count-1 do
      begin
        if Pos('page_select', parse.Strings[i]) <> 0 then
         // if Pos('Page', parse.Strings[i+2]) <> 0 then
        begin
          j:= i+2;
          s:= parse.Strings[j];
          while GetTagName(parse.Strings[j]) = 'option' do
          begin
            Inc(manager.container.pageNumber);
            Inc(j, 3);
          end;
          break;
        end;
      end;
    end;
    parse.Free;
    l.Free;
  end;

  function GetHentai2ReadPageNumber: Boolean;
  var
    s   : String;
    i, j: Cardinal;
    l   : TStringList;
  begin
    l:= TStringList.Create;
    parse:= TStringList.Create;
    Result:= GetPage(TObject(l),
                     HENTAI2READ_ROOT + URL,
                     manager.container.manager.retryConnect);
    Parser:= TjsFastHTMLParser.Create(PChar(l.Text));
    s:= HENTAI2READ_ROOT + URL;
    Parser.OnFoundTag := OnTag;
    Parser.OnFoundText:= OnText;
    Parser.Exec;
    Parser.Free;
    if parse.Count>0 then
    begin
      manager.container.pageNumber:= 0;
      for i:= 0 to parse.Count-1 do
      begin
        if (GetTagName(parse.Strings[i]) = 'select') AND
           (GetAttributeValue(GetTagAttribute(parse.Strings[i], 'class='))='cbo_wpm_pag') then
        begin
          j:= i+1;
          while GetTagName(parse.Strings[j]) = 'option' do
          begin
            Inc(manager.container.pageNumber);
            Inc(j, 3);
          end;
          break;
        end;
      end;
    end;
    parse.Free;
    l.Free;
  end;

begin
  manager.container.pageNumber:= 0;
  if manager.container.mangaSiteID = ANIMEA_ID then
    Result:= GetAnimeAPageNumber
  else
  if manager.container.mangaSiteID = MANGAHERE_ID then
    Result:= GetMangaHerePageNumber
  else
  if manager.container.mangaSiteID = MANGAINN_ID then
    Result:= GetMangaInnPageNumber
  else
  if manager.container.mangaSiteID = OURMANGA_ID then
    Result:= GetOurMangaPageNumber
  else
  if manager.container.mangaSiteID = BATOTO_ID then
    Result:= GetBatotoPageNumber
  else
  if manager.container.mangaSiteID = VNSHARING_ID then
  begin
    // all of the page links are in a html page
    Result:= TRUE;
    manager.container.pageNumber:= 1;
  end
  else
  if manager.container.mangaSiteID = HENTAI2READ_ID then
    Result:= GetHentai2ReadPageNumber;
end;

function    TDownloadThread.GetLinkPageFromURL(const URL: String): Boolean;
var
  Parser: TjsFastHTMLParser;

  function GetAnimeALinkPage: Boolean;
  var
    i: Cardinal;
    l: TStringList;
  begin
    l:= TStringList.Create;
    Result:= GetPage(TObject(l),
                     ANIMEA_ROOT +
                     StringReplace(URL, '.html', '', []) +
                     '-page-'+IntToStr(workPtr+1)+'.html',
                     manager.container.manager.retryConnect);
    for i:= 0 to l.Count-1 do
      if (Pos('class="mangaimg', l.Strings[i])<>0) then
      begin
        manager.container.pageLinks.Strings[workPtr]:= GetString(l.Strings[i], '<img src="', '"');
        break;
      end;
    l.Free;
  end;

  function GetMangaHereLinkPage: Boolean;
  var
    i: Cardinal;
    l: TStringList;
  begin
    l:= TStringList.Create;
    if workPtr > 0 then
      Result:= GetPage(TObject(l),
                       MANGAHERE_ROOT + URL + IntToStr(workPtr+1)+'.html',
                       manager.container.manager.retryConnect)
    else
      Result:= GetPage(TObject(l),
                       MANGAHERE_ROOT + URL,
                       manager.container.manager.retryConnect);
    parse:= TStringList.Create;

    Parser:= TjsFastHTMLParser.Create(PChar(l.Text));
    Parser.OnFoundTag := OnTag;
    Parser.OnFoundText:= OnText;
    Parser.Exec;
    Parser.Free;
    if parse.Count>0 then
    begin
      for i:= 0 to parse.Count-1 do
        if (Pos('http://c.mhcdn.net/store/', parse.Strings[i])<>0) then
        begin
          manager.container.pageLinks.Strings[workPtr]:= GetAttributeValue(GetTagAttribute(parse.Strings[i], 'src='));
          parse.Free;
          l.Free;
          exit;
        end;
    end;
    parse.Free;
    l.Free;
  end;

  function GetMangaInnLinkPage: Boolean;
  var
    i: Cardinal;
    l: TStringList;
  begin
    l:= TStringList.Create;
    Result:= GetPage(TObject(l),
                     MANGAINN_ROOT + URL + '/page_'+IntToStr(workPtr+1),
                     manager.container.manager.retryConnect);
    parse:= TStringList.Create;
    Parser:= TjsFastHTMLParser.Create(PChar(l.Text));
    Parser.OnFoundTag := OnTag;
    Parser.OnFoundText:= OnText;
    Parser.Exec;
    Parser.Free;

    if parse.Count>0 then
    begin
      for i:= 0 to parse.Count-1 do
        if GetTagName(parse.Strings[i]) = 'img' then
          if GetAttributeValue(GetTagAttribute(parse.Strings[i], 'id='))='imgPage' then
          begin
            manager.container.pageLinks.Strings[workPtr]:= GetAttributeValue(GetTagAttribute(parse.Strings[i], 'src='));
            break;
          end;
    end;
    parse.Free;
    l.Free;
  end;

  function GetOurMangaLinkPage: Boolean;
  var
    j,
    i: Cardinal;
    l: TStringList;
  begin
    l:= TStringList.Create;
    Result:= GetPage(TObject(l),
                     OURMANGA_ROOT + URL + '/' + manager.container.pageContainerLinks.Strings[workPtr],
                     manager.container.manager.retryConnect);
    parse:= TStringList.Create;
    Parser:= TjsFastHTMLParser.Create(PChar(l.Text));
    Parser.OnFoundTag := OnTag;
    Parser.OnFoundText:= OnText;
    Parser.Exec;
    Parser.Free;
    if parse.Count>0 then
    begin
      for i:= 0 to parse.Count-1 do
        if (GetTagName(parse.Strings[i]) = 'div') AND
           (GetAttributeValue(GetTagAttribute(parse.Strings[i], 'class=')) = 'prev_next_top') then
        begin
          j:= i;
          repeat
            Dec(j);
            if GetTagName(parse.Strings[j]) = 'img' then
            begin
              manager.container.pageLinks.Strings[workPtr]:= GetAttributeValue(GetTagAttribute(parse.Strings[j], 'src='));
              parse.Free;
              l.Free;
              exit;
            end;
          until j = 0;
        end;
    end;
    parse.Free;
    l.Free;
  end;

  function GetBatotoLinkPage: Boolean;
  var
    i: Cardinal;
    l: TStringList;
  begin
    l:= TStringList.Create;
    Result:= GetPage(TObject(l),
                     BATOTO_ROOT + DecodeURL(URL) + '/'+IntToStr(workPtr+1),
                     manager.container.manager.retryConnect);
    parse:= TStringList.Create;
    Parser:= TjsFastHTMLParser.Create(PChar(l.Text));
    Parser.OnFoundTag := OnTag;
    Parser.OnFoundText:= OnText;
    Parser.Exec;
    Parser.Free;

    if parse.Count>0 then
    begin
      for i:= 0 to parse.Count-1 do
        if GetTagName(parse.Strings[i]) = 'img' then
          if (Pos('http://img.batoto.net/comics/', parse.Strings[i])>0) AND
             (Pos('z-index: 1003', parse.Strings[i])>0) then
          begin
            manager.container.pageLinks.Strings[workPtr]:= GetAttributeValue(GetTagAttribute(parse.Strings[i], 'src='));
            break;
          end;
    end;
    parse.Free;
    l.Free;
  end;

  function GetVnSharingLinkPage: Boolean;
  var
    s: String;
    j,
    i: Cardinal;
    l: TStringList;
  begin
    l:= TStringList.Create;
    Result:= GetPage(TObject(l),
                     VNSHARING_ROOT + URL,
                     manager.container.manager.retryConnect);
    parse:= TStringList.Create;
    Parser:= TjsFastHTMLParser.Create(PChar(l.Text));
    Parser.OnFoundTag := OnTag;
    Parser.OnFoundText:= OnText;
    Parser.Exec;
    Parser.Free;
    if parse.Count>0 then
    begin
      manager.container.pageLinks.Clear;
      for i:= 0 to parse.Count-1 do
      begin
        if Pos('lstImages.push("', parse.Strings[i]) > 0 then
        begin
          s:= parse.Strings[i];
          repeat
            j:= Pos('lstImages.push("', s);
            manager.container.pageLinks.Add(EncodeUrl(GetString(s, 'lstImages.push("', '");')));
            Delete(s, Pos('lstImages.push("', s), 16);
            j:= Pos('lstImages.push("', s);
          until j = 0;
        end;
      end;
    end;
    parse.Free;
    l.Free;
  end;

  function GetHentai2ReadLinkPage: Boolean;
  var
    i: Cardinal;
    l: TStringList;
  begin
    l:= TStringList.Create;
    Result:= GetPage(TObject(l),
                     HENTAI2READ_ROOT + URL + IntToStr(workPtr+1)+'/',
                     manager.container.manager.retryConnect);
    parse:= TStringList.Create;
    Parser:= TjsFastHTMLParser.Create(PChar(l.Text));
    Parser.OnFoundTag := OnTag;
    Parser.OnFoundText:= OnText;
    Parser.Exec;
    Parser.Free;

    if parse.Count>0 then
    begin
      for i:= 0 to parse.Count-1 do
        if (GetTagName(parse.Strings[i]) = 'img') AND
           (GetAttributeValue(GetTagAttribute(parse.Strings[i], 'id='))='img_mng_enl') then
        begin
          manager.container.pageLinks.Strings[workPtr]:= GetAttributeValue(GetTagAttribute(parse.Strings[i], 'src='));
          break;
        end;
    end;
    parse.Free;
    l.Free;
  end;

var
  s: String;

begin
  if manager.container.pageLinks.Strings[workPtr] <> 'W' then exit;
  if manager.container.mangaSiteID = ANIMEA_ID then
    Result:= GetAnimeALinkPage
  else
  if manager.container.mangaSiteID = MANGAHERE_ID then
    Result:= GetMangaHereLinkPage
  else
  if manager.container.mangaSiteID = MANGAINN_ID then
    Result:= GetMangaInnLinkPage
  else
  if manager.container.mangaSiteID = OURMANGA_ID then
    Result:= GetOurMangaLinkPage
  else
  if manager.container.mangaSiteID = BATOTO_ID then
    Result:= GetBatotoLinkPage
  else
  if manager.container.mangaSiteID = VNSHARING_ID then
    Result:= GetVnSharingLinkPage
  else
  if manager.container.mangaSiteID = HENTAI2READ_ID then
    Result:= GetHentai2ReadLinkPage;
end;

function    TDownloadThread.DownloadPage: Boolean;
begin
  if (manager.container.pageLinks.Strings[workPtr] = '') OR
     (manager.container.pageLinks.Strings[workPtr] = 'W') then exit;
  SavePage(manager.container.pageLinks.Strings[workPtr],
           manager.container.downloadInfo.SaveTo+
           '/'+manager.container.chapterName.Strings[manager.container.currentDownloadChapterPtr],
           Format('%.3d', [workPtr+1]),
           manager.container.manager.retryConnect);
  manager.container.pageLinks.Strings[workPtr]:= '';
  SetCurrentDir(oldDir);
end;

// ----- TTaskThread -----

constructor TTaskThread.Create;
begin
  isTerminated:= FALSE;
  isSuspended := TRUE;
  FreeOnTerminate:= TRUE;
  threads     := TDownloadThreadList.Create;
  inherited Create(FALSE);
end;

destructor  TTaskThread.Destroy;
begin
  Stop;
  threads.Free;
  isTerminated:= TRUE;
  inherited Destroy;
end;

procedure   TTaskThread.Repaint;
begin
  MainForm.vtDownload.Repaint;
end;

procedure   TTaskThread.Compress;
var
  Compresser: TCompress;
begin
  if (container.manager.compress = 1) then
  begin
    Sleep(100);
    Compresser:= TCompress.Create;
    Compresser.Path:= container.downloadInfo.SaveTo+'/'+
                      container.chapterName.Strings[container.currentDownloadChapterPtr];
    Compresser.Execute;
    Compresser.Free;
  end;
end;

procedure   TTaskThread.ShowBaloon;
begin
  MainForm.TrayIcon.BalloonHint:= '"'+container.downloadInfo.title+'" - '+stFinish;
  MainForm.TrayIcon.ShowBalloonHint;
end;

procedure   TTaskThread.Checkout;
var
  i: Cardinal;
begin
  Sleep(100);
  if container.activeThreadCount >= container.manager.maxDLThreadsPerTask then exit;
  for i:= 0 to container.manager.maxDLThreadsPerTask-1 do
  begin
    if i >= threads.Count then
    begin
      while isSuspended do Sleep(100);
      Inc(container.activeThreadCount);
      threads.Add(TDownloadThread.Create);
      threads.Items[threads.Count-1].manager:= self;
      threads.Items[threads.Count-1].workPtr:= container.workPtr;
      threads.Items[threads.Count-1].checkStyle:= Flag;
      threads.Items[threads.Count-1].isSuspended:= FALSE;
      Inc(container.workPtr);
      if Flag = CS_GETPAGELINK then
        Inc(container.currentPageNumber);
      exit;
    end
    else
    if (threads.Items[i].isTerminated) then
    begin
      while isSuspended do Sleep(100);
      Inc(container.activeThreadCount);
      threads.Items[i]:= TDownloadThread.Create;
      threads.Items[i].manager:= self;
      threads.Items[i].workPtr:= container.workPtr;
      threads.Items[i].checkStyle:= Flag;
      threads.Items[i].isSuspended:= FALSE;
      Inc(container.workPtr);
      if Flag = CS_GETPAGELINK then
        Inc(container.currentPageNumber);
      exit;
    end;
  end;
end;

procedure   TTaskThread.Execute;

  procedure  WaitFor;
  var
    done: Boolean;
    i   : Cardinal;
  begin
    repeat
      done:= TRUE;
      for i:= 0 to threads.Count-1 do
       // if threads[i].manager = @self then
          if NOT threads[i].isTerminated then
          begin
            done:= FALSE;
            sleep(100);
          end;
    until done;
  end;

var
  i, count: Cardinal;
begin
  while isSuspended do Sleep(100);
  while container.currentDownloadChapterPtr < container.chapterLinks.Count do
  begin
    if Terminated then exit;
    container.activeThreadCount:= 1;
    while isSuspended do Sleep(100);

    // get page number
    if container.currentPageNumber = 0 then
    begin
      if Terminated then exit;
      Stop(FALSE);
      threads.Add(TDownloadThread.Create);
      i:= threads.Count-1;
       // container.Status:= STATUS_PREPARE;
      threads.Items[threads.Count-1].manager:= self;
      threads.Items[threads.Count-1].workPtr:= container.workPtr;
      threads.Items[threads.Count-1].checkStyle:= CS_GETPAGENUMBER;
      threads.Items[threads.Count-1].isSuspended:= FALSE;
      CheckPath(container.downloadInfo.SaveTo+
                '/'+
                container.chapterName.Strings[container.currentDownloadChapterPtr]);
      while (isSuspended) OR (NOT threads.Items[threads.Count-1].isTerminated) do
        Sleep(100);
    end;

    //get page links
   // if container.currentPageNumber < container.pageNumber then
    begin
      container.workPtr:= 0;//container.currentPageNumber;
   //   if container.workPtr > 0 then
   //     Dec(container.workPtr);
      container.downloadInfo.iProgress:= 0;
      while container.workPtr < container.pageLinks.Count{container.pageNumber} do
      begin
        if Terminated then exit;
        Flag:= CS_GETPAGELINK;
        Checkout;
        container.downloadInfo.Progress:= Format('%d/%d', [container.workPtr, container.pageNumber]);
        container.downloadInfo.Status  := Format('%s (%d/%d)', [stPreparing, container.currentDownloadChapterPtr, container.chapterLinks.Count]);
        Inc(container.downloadInfo.iProgress);
        {$IFDEF WIN32}
        MainForm.vtDownload.Repaint;
        {$ELSE}
        Synchronize(Repaint);
        {$ENDIF}
      end;
      WaitFor;
    end;

    //download pages
   // container.Status:= STATUS_DOWNLOAD;
    container.workPtr:= 0;
    container.downloadInfo.iProgress:= 0;

    // will bypass the download section if links = nil
    if container.chapterLinks.Count > 0 then
    begin
      while container.workPtr < container.pageLinks.Count do
      begin
        if Terminated then exit;
        Flag:= CS_DOWNLOAD;
        Checkout;
        container.downloadInfo.Progress:= Format('%d/%d', [container.workPtr, container.pageLinks.Count]);
        container.downloadInfo.Status  := Format('%s (%d/%d)', [stDownloading, container.currentDownloadChapterPtr, container.chapterLinks.Count]);
        Inc(container.downloadInfo.iProgress);
        {$IFDEF WIN32}
        MainForm.vtDownload.Repaint;
        {$ELSE}
        Synchronize(Repaint);
        {$ENDIF}
      end;
      WaitFor;
      Synchronize(Compress);
    end;
    if Terminated then exit;
    container.currentPageNumber:= 0;
    container.pageLinks.Clear;
    Inc(container.currentDownloadChapterPtr);
  end;
  Synchronize(ShowBaloon);
  Terminate;
end;

procedure   TTaskThread.Stop(const check: Boolean = TRUE);
var
  i: Cardinal;
begin
  if check then
  begin
    if (container.workPtr >= container.pageLinks.Count) AND
       (container.currentDownloadChapterPtr >= container.chapterLinks.Count) then
    begin
      container.downloadInfo.Status  := stFinish;
      container.downloadInfo.Progress:= '';
      container.Status:= STATUS_FINISH;
      container.manager.CheckAndActiveTask;
      {$IFDEF WIN32}
      MainForm.vtDownload.Repaint;
      {$ELSE}
      Synchronize(Repaint);
      {$ENDIF}
    end
    else
    begin
      container.downloadInfo.Status  := Format('%s (%d/%d)', [stStop, container.currentDownloadChapterPtr, container.chapterLinks.Count]);
      container.Status:= STATUS_STOP;
      container.manager.CheckAndActiveTask;
      {$IFDEF WIN32}
      MainForm.vtDownload.Repaint;
      {$ELSE}
      Synchronize(Repaint);
      {$ENDIF}
    end;
  end;
  {if check then
  begin
    if threads.Count = 0 then exit;
    for i:= 0 to threads.Count-1 do
      if (Assigned(threads.Items[i])) AND (NOT threads.Items[i].isTerminated) then
      begin
       // threads.Items[i].Suspend;
        threads.Items[i].Terminate;
       // threads.Items[i].Free;
      end;
  end;}
  threads.Clear;
end;

// ----- TTaskThreadContainer -----

constructor TTaskThreadContainer.Create;
begin
  chapterLinks     := TStringList.Create;
  chapterName      := TStringList.Create;
  pageLinks        := TStringList.Create;
  pageContainerLinks:= TStringList.Create;
  workPtr:= 0;
  currentPageNumber:= 0;
  currentDownloadChapterPtr:= 0;
  inherited Create;
end;

destructor  TTaskThreadContainer.Destroy;
begin
  thread.Terminate;
  pageContainerLinks.Free;
  pageLinks.Free;
  chapterName.Free;
  chapterLinks.Free;
  inherited Destroy;
end;

// ----- TDownloadThread -----

{constructor TDownloadThread.Create;
begin
  FreeOnTerminate:= TRUE;
  inherited Create(TRUE);
end;

procedure   TDownloadThread.Compress;
var
  Compresser: TCompress;
begin
  if (threadID = 0) AND (manager.compress = 1) then
  begin
    Sleep(100);
    Compresser:= TCompress.Create;
    Compresser.Path:= manager.downloadInfo[taskID].SaveTo+'/'+
                      manager.chapterName[taskID].Strings[manager.chapterPtr.Items[taskID]-1];
    Compresser.Execute;
    Compresser.Free;
  end;
end;

procedure   TDownloadThread.IncreasePrepareProgress;
begin
  manager.downloadInfo[taskID].Progress:=
    IntToStr(manager.downloadInfo[taskID].iProgress+1)+'/'+IntToStr(pageNumber);
  Inc(manager.downloadInfo[taskID].iProgress);
  MainForm.vtDownload.Repaint;
end;

procedure   TDownloadThread.IncreaseDownloadProgress;
begin
  manager.downloadInfo[taskID].Progress:=
    IntToStr(manager.downloadInfo[taskID].iProgress+1)+'/'+IntToStr(manager.pageLinks[taskID].Count);
  Inc(manager.downloadInfo[taskID].iProgress);
  MainForm.vtDownload.Repaint;
end;

procedure   TDownloadThread.Execute;
var
  i, count, sum: Cardinal;
begin
  i:= manager.activeThreadsPerTask.Count;
  pass0:= FALSE;
  pass1:= FALSE;
  pass2:= FALSE;
  lastPass:= FALSE;
  while manager.chapterPtr.Items[taskID] < manager.chapterLinks[taskID].Count do
  begin
    // prepare
    chapterPtr:= manager.chapterPtr.Items[taskID];
    // pass 0
    pass0:= TRUE;
    repeat
      Sleep(16);
      count:= 0;
      for i:= 0 to manager.threads.Count-1 do
        if (manager.threads[i].taskID = taskID) AND
           (manager.threads[i].pass0) then
          Inc(count);
    until count = manager.activeThreadsPerTask.Items[taskID];
    // pass0:= FALSE;

    // pass 1
    if manager.pageLinks[taskID].Count = 0 then
    begin
      if threadID = 0 then
      begin
        CheckPath(manager.downloadInfo[taskID].SaveTo+
                  '/'+
                  manager.chapterName[taskID].Strings[manager.chapterPtr.Items[taskID]]);
        GetPageNumberFromURL(manager.chapterLinks[taskID].Strings[manager.chapterPtr.Items[taskID]]);
        for i:= 0 to pageNumber-1 do
          manager.pageLinks[taskID].Add('');
        // sync page number to all the thread have the same taskID
        for i:= 0 to manager.threads.Count - 1 do
          if taskID = manager.threads[i].taskID then
          begin
            manager.threads[i].pageNumber:= pageNumber;
            manager.threads[i].pass1:= TRUE;
          end;
      end;

      if threadID = 0 then
      begin
        manager.downloadInfo[taskID].iProgress:= 0;
        manager.downloadInfo[taskID].Status:= Format('%s (%d/%d)', [stPreparing, chapterPtr+1, manager.chapterLinks[taskID].Count]);
      end;
      repeat
        Sleep(16);
        count:= 0;
        for i:= 0 to manager.threads.Count-1 do
          if (manager.threads[i].taskID = taskID) AND
             (manager.threads[i].pass1) then
            Inc(count);
      until count = manager.activeThreadsPerTask.Items[taskID];

      workPtr:= threadID;
      while (NOT Terminated) AND (workPtr <= pageNumber-1) do
      begin
        GetLinkPageFromURL(manager.chapterLinks[taskID].Strings[manager.chapterPtr.Items[taskID]]);
        Sleep(16);
        Inc(workPtr, manager.activeThreadsPerTask.Items[taskID]);
        Synchronize(IncreasePrepareProgress);
      end;
   // pass1:= FALSE;
      pass2:= TRUE;

    // pass 2

      repeat
        if threadID = 0 then
          manager.downloadInfo[taskID].iProgress:= 0;
        Sleep(16);
        count:= 0;
        for i:= 0 to manager.threads.Count-1 do
          if (manager.threads[i].taskID = taskID) AND
             (manager.threads[i].pass2) then
            Inc(count);
      until count = manager.activeThreadsPerTask.Items[taskID];
    end
    else
    begin
      pass1:= TRUE;
      pass2:= TRUE;
    end;
    if threadID = 0 then
      manager.downloadInfo[taskID].Status:= Format('%s (%d/%d)', [stDownloading, chapterPtr+1, manager.chapterLinks[taskID].Count]);

    workPtr:= threadID;
    while (NOT Terminated) AND (workPtr <= manager.pageLinks[taskID].Count-1) do
    begin
      DownloadPage;
      Sleep(16);
      Inc(workPtr, manager.activeThreadsPerTask.Items[taskID]);
      Synchronize(IncreaseDownloadProgress);
    end;

    // prepare to download another chapter or exit

    pass0:= FALSE;
    pass1:= FALSE;
    repeat
      if threadID = 0 then
        Inc(manager.chapterPtr.Items[taskID]);
      Sleep(16);
      count:= 0;
      for i:= 0 to manager.threads.Count-1 do
        if (manager.threads[i].taskID = taskID) AND
           (manager.threads[i].workPtr > manager.pageLinks[taskID].Count-1) AND
           (chapterPtr <> manager.chapterPtr.Items[taskID]) then
          Inc(count);
    until count = manager.activeThreadsPerTask.Items[taskID];
    Compress;
    if threadID = 0 then
      manager.pageLinks[taskID].Clear;
    pass2:= FALSE;
  end;

  // last pass - raise finish flag
  lastPass:= TRUE;
  isTerminate:= TRUE;
  repeat
    Sleep(16);
    count:= 0;
    for i:= 0 to manager.threads.Count-1 do
      if (manager.threads[i].taskID = taskID) AND
         (manager.threads[i].lastPass) then
        Inc(count);
  until count = manager.activeThreadsPerTask.Items[taskID];

  // ID 0 will do the finish part
  if threadID = 0 then
  begin
    Sleep(1000);
    manager.downloadInfo[taskID].Progress:= '';
    while manager.isFinishTaskAccessed do Sleep(100);
    manager.isFinishTaskAccessed:= TRUE;
    manager.FinishTask(taskID);
    Terminate;
  end
  else
    Suspend;
end;

function    TDownloadThread.GetPageNumberFromURL(const URL: String): Boolean;
  function GetAnimeAPageNumber: Boolean;
  var
    i: Cardinal;
    l: TStringList;
  begin
    l:= TStringList.Create;
    Result:= GetPage(TObject(l), ANIMEA_ROOT +
                                 StringReplace(URL, '.html', '', []) +
                                 '-page-1.html',
                                 manager.retryConnect);
    for i:= 0 to l.Count-1 do
      if (Pos('Page 1 of ', l.Strings[i])<>0) then
      begin
        pageNumber:= StrToInt(GetString(l.Strings[i], 'Page 1 of ', '<'));
        break;
      end;
    l.Free;
  end;

begin
  pageNumber:= 0;
  if mangaSiteID = ANIMEA_ID then
    Result:= GetAnimeAPageNumber;
end;

function    TDownloadThread.GetLinkPageFromURL(const URL: String): Boolean;
  function GetAnimeALinkPage: Boolean;
  var
    i: Cardinal;
    l: TStringList;
  begin
    l:= TStringList.Create;
    Result:= GetPage(TObject(l),
                     ANIMEA_ROOT +
                     StringReplace(URL, '.html', '', []) +
                     '-page-'+IntToStr(workPtr+1)+'.html',
                     manager.retryConnect);
    for i:= 0 to l.Count-1 do
      if (Pos('class="mangaimg', l.Strings[i])<>0) then
      begin
        manager.pageLinks[taskID].Strings[workPtr]:= GetString(l.Strings[i], '<img src="', '"');
        break;
      end;
    l.Free;
  end;

begin
  if mangaSiteID = ANIMEA_ID then
    Result:= GetAnimeALinkPage;
end;

function    TDownloadThread.DownloadPage: Boolean;
var
  s, ext: String;
begin
  if manager.pageLinks[taskID].Strings[workPtr] = '' then exit;
  s:= manager.pageLinks[taskID].Strings[workPtr];
  if (Pos('.jpeg', LowerCase(s))<>0) OR (Pos('.jpg', LowerCase(s))<>0) then
    ext:= '.jpg'
  else
  if Pos('.png', LowerCase(s))<>0 then
    ext:= '.png'
  else
  if Pos('.gif', LowerCase(s))<>0 then
    ext:= '.gif';
  SetCurrentDir(oldDir);
  SavePage(manager.pageLinks[taskID].Strings[workPtr],
           Format('%s/%.3d%s',
                  [manager.downloadInfo[taskID].SaveTo+
                  '/'+manager.chapterName[taskID].Strings[chapterPtr],
                  workPtr+1, ext]), manager.retryConnect);
  manager.pageLinks[taskID].Strings[workPtr]:= '';
  SetCurrentDir(oldDir);
end;
    }
// ----- TDownloadManager -----

constructor TDownloadManager.Create;
begin
  inherited Create;

  // Create INI file
  ini:= TIniFile.Create(WORK_FOLDER + WORK_FILE);
  ini.CacheUpdates:= FALSE;
  containers:= TTaskThreadContainerList.Create;
  isFinishTaskAccessed:= FALSE;

  // Restore old INI file
  Restore;
end;

destructor  TDownloadManager.Destroy;
var i: Cardinal;
begin
  if containers.Count <> 0 then
    for i:= 0 to containers.Count-1 do
      if NOT containers.Items[i].thread.isTerminated then
        containers.Items[i].thread.Terminate;
  ini.Free;
  inherited Destroy;
end;

procedure   TDownloadManager.Restore;
var
  s: String;
  tmp,
  i: Cardinal;
begin
  // Restore general information first
  if containers.Count > 0 then
  begin
    for i:= 0 to containers.Count-1 do
    begin
      containers.Items[i].Destroy;
    end;
    containers.Clear;
  end;
  tmp:= ini.ReadInteger('general', 'NumberOfTasks', 0);
  if tmp = 0 then exit;
  for i:= 0 to tmp-1 do
  begin
    containers.Add(TTaskThreadContainer.Create);
    containers.Items[i].manager:= self;
  end;

  // Restore chapter links, chapter name and page links
  for i:= 0 to containers.Count-1 do
  begin
    s:= ini.ReadString('task'+IntToStr(i), 'ChapterLinks', '');
    if s <> '' then
      GetParams(containers.Items[i].chapterLinks, s);
    s:= ini.ReadString('task'+IntToStr(i), 'ChapterName', '');
    if s <> '' then
      GetParams(containers.Items[i].chapterName, s);
    s:= ini.ReadString('task'+IntToStr(i), 'PageLinks', '');
    if s <> '' then
      GetParams(containers.Items[i].pageLinks, s);
    s:= ini.ReadString('task'+IntToStr(i), 'PageContainerLinks', '');
    if s <> '' then
      GetParams(containers.Items[i].pageContainerLinks, s);
    containers.Items[i].Status                   := ini.ReadInteger('task'+IntToStr(i), 'TaskStatus', 0);
    containers.Items[i].currentDownloadChapterPtr:= ini.ReadInteger('task'+IntToStr(i), 'ChapterPtr', 0);
    containers.Items[i].pageNumber               := ini.ReadInteger('task'+IntToStr(i), 'NumberOfPages', 0);
    containers.Items[i].currentPageNumber        := ini.ReadInteger('task'+IntToStr(i), 'CurrentPage', 0);

    containers.Items[i].downloadInfo.title   := ini.ReadString('task'+IntToStr(i), 'Title', 'NULL');
    containers.Items[i].downloadInfo.status  := ini.ReadString('task'+IntToStr(i), 'Status', 'NULL');
    containers.Items[i].downloadInfo.Progress:= ini.ReadString('task'+IntToStr(i), 'Progress', 'NULL');
    containers.Items[i].downloadInfo.website := ini.ReadString('task'+IntToStr(i), 'Website', 'NULL');
    containers.Items[i].downloadInfo.saveTo  := ini.ReadString('task'+IntToStr(i), 'SaveTo', 'NULL');
    containers.Items[i].downloadInfo.dateTime:= ini.ReadString('task'+IntToStr(i), 'DateTime', 'NULL');
    containers.Items[i].mangaSiteID:= GetMangaSiteID(containers.Items[i].downloadInfo.website);
  end;
end;

procedure   TDownloadManager.Backup;
var
  i: Cardinal;
begin
  // Erase all sections
  for i:= 0 to ini.ReadInteger('general', 'NumberOfTasks', 0) do
    ini.EraseSection('task'+IntToStr(i));
  ini.EraseSection('general');

  // backup
  if containers.Count > 0 then
  begin
    ini.WriteInteger('general', 'NumberOfTasks', containers.Count);

    for i:= 0 to containers.Count-1 do
    begin
     // ini.WriteInteger('task'+IntToStr(i), 'NumberOfChapterLinks', containers.Items[i].chapterLinks.Count);
     // ini.WriteInteger('task'+IntToStr(i), 'NumberOfChapterName', containers.Items[i].chapterName.Count);
     // ini.WriteInteger('task'+IntToStr(i), 'NumberOfPageLinks', containers.Items[i].pageLinks.Count);

      ini.WriteString('task'+IntToStr(i), 'ChapterLinks', SetParams(containers.Items[i].chapterLinks));
      ini.WriteString('task'+IntToStr(i), 'ChapterName', SetParams(containers.Items[i].ChapterName));
      if containers.Items[i].pageLinks.Count > 0 then
        ini.WriteString('task'+IntToStr(i), 'PageLinks', SetParams(containers.Items[i].pageLinks));
      if containers.Items[i].pageContainerLinks.Count > 0 then
        ini.WriteString('task'+IntToStr(i), 'PageContainerLinks', SetParams(containers.Items[i].pageContainerLinks));

      ini.WriteInteger('task'+IntToStr(i), 'TaskStatus', containers.Items[i].Status);
      ini.WriteInteger('task'+IntToStr(i), 'ChapterPtr', containers.Items[i].currentDownloadChapterPtr);
      ini.WriteInteger('task'+IntToStr(i), 'NumberOfPages', containers.Items[i].pageNumber);
      ini.WriteInteger('task'+IntToStr(i), 'CurrentPage', containers.Items[i].currentPageNumber);

      ini.WriteString ('task'+IntToStr(i), 'Title', containers.Items[i].downloadInfo.title);
      ini.WriteString ('task'+IntToStr(i), 'Status', containers.Items[i].downloadInfo.status);
      ini.WriteString ('task'+IntToStr(i), 'Progress', containers.Items[i].downloadInfo.Progress);
      ini.WriteString ('task'+IntToStr(i), 'Website', containers.Items[i].downloadInfo.website);
      ini.WriteString ('task'+IntToStr(i), 'SaveTo', containers.Items[i].downloadInfo.saveTo);
      ini.WriteString ('task'+IntToStr(i), 'DateTime', containers.Items[i].downloadInfo.dateTime);
    end;
  end;
  ini.UpdateFile;
end;

procedure   TDownloadManager.AddTask;
begin
  containers.Add(TTaskThreadContainer.Create);
  containers.Items[containers.Count-1].manager:= self;
end;

procedure   TDownloadManager.CheckAndActiveTask;
var
  i    : Cardinal;
  count: Cardinal = 0;
begin
  if containers.Count = 0 then exit;
  for i:= 0 to containers.Count-1 do
  begin
    if containers.Items[i].Status = STATUS_DOWNLOAD then
      Inc(count)
    else
    if containers.Items[i].Status = STATUS_WAIT then
    begin
      ActiveTask(i);
      Inc(count);
    end;
    if count >= maxDLTasks then
      exit;
  end;
end;

function    TDownloadManager.CanActiveTask: Boolean;
var
  i    : Cardinal;
  count: Cardinal = 0;
begin
  Result:= FALSE;
  for i:= 0 to containers.Count-1 do
  begin
    if containers.Items[i].Status = STATUS_DOWNLOAD then
      Inc(count);
    if count >= maxDLTasks then
      exit;
  end;
  Result:= TRUE;
end;

procedure   TDownloadManager.CheckAndActiveTaskAtStartup;

  procedure   ActiveTaskAtStartup(const taskID: Cardinal);
  var
    i, pos: Cardinal;
  begin
    i:= maxDLTasks;
    if taskID >= containers.Count then exit;
    if (NOT Assigned(containers.Items[taskID])) then exit;
    if (containers.Items[taskID].Status = STATUS_WAIT) AND
       (containers.Items[taskID].Status = STATUS_STOP) AND
       (containers.Items[taskID].Status = STATUS_FINISH) then exit;
    containers.Items[taskID].Status:= STATUS_DOWNLOAD;
    containers.Items[taskID].thread:= TTaskThread.Create;
    containers.Items[taskID].thread.container:= containers.Items[taskID];
    containers.Items[taskID].thread.isSuspended:= FALSE;
  end;

var
  i    : Cardinal;
  count: Cardinal = 0;
begin
  if containers.Count = 0 then exit;
  for i:= 0 to containers.Count-1 do
  begin
    if containers.Items[i].Status = STATUS_DOWNLOAD then
    begin
      ActiveTaskAtStartup(i);
      Inc(count);
    end;
  end;
end;

procedure   TDownloadManager.ActiveTask(const taskID: Cardinal);
var
  i, pos: Cardinal;
begin
  i:= maxDLTasks;
  // conditions
 // if pos >= maxDLTasks then exit;
  if taskID >= containers.Count then exit;
  if (NOT Assigned(containers.Items[taskID])) then exit;
  if (containers.Items[taskID].Status = STATUS_DOWNLOAD) AND
     (containers.Items[taskID].Status = STATUS_PREPARE) AND
     (containers.Items[taskID].Status = STATUS_FINISH) then exit;
  containers.Items[taskID].Status:= STATUS_DOWNLOAD;
  containers.Items[taskID].thread:= TTaskThread.Create;
  containers.Items[taskID].thread.container:= containers.Items[taskID];
  containers.Items[taskID].thread.isSuspended:= FALSE;
  // TODO
end;

procedure   TDownloadManager.StopTask(const taskID: Cardinal);
var
  i: Cardinal;
begin
  // conditions
  if taskID >= containers.Count then exit;
  if (containers.Items[taskID].Status <> STATUS_DOWNLOAD) AND
     (containers.Items[taskID].Status <> STATUS_WAIT) then exit;
  // check and stop any active thread
  if containers.Items[taskID].Status = STATUS_DOWNLOAD then
  begin
    containers.Items[taskID].thread.Terminate;
    containers.Items[taskID].Status:= STATUS_STOP;
  end
  else
  if containers.Items[taskID].Status = STATUS_WAIT then
  begin
    containers.Items[taskID].downloadInfo.Status:= stStop;
    containers.Items[taskID].Status:= STATUS_STOP;
  end;
 // containers.Items[taskID].downloadInfo.Status:= Format('%s (%d/%d)', [stStop, containers.Items[taskID].currentDownloadChapterPtr, containers.Items[taskID].chapterLinks.Count]);
  containers.Items[taskID].Status:= STATUS_STOP;
  Backup;
  Sleep(1000);
  CheckAndActiveTask;
end;

procedure   TDownloadManager.StopAllTasks;
var
  i: Cardinal;
begin
  if containers.Count = 0 then exit;
  // check and stop any active thread
  for i:= 0 to containers.Count-1 do
  begin
    if containers.Items[i].Status = STATUS_DOWNLOAD then
    begin
      containers.Items[i].thread.Terminate;
      containers.Items[i].Status:= STATUS_STOP;
    end
    else
    if containers.Items[i].Status = STATUS_WAIT then
    begin
      containers.Items[i].downloadInfo.Status:= stStop;
      containers.Items[i].Status:= STATUS_STOP;
    end;
  end;
  Backup;
  MainForm.vtDownload.Repaint;
end;

procedure   TDownloadManager.StopAllDownloadTasksForExit;
var
  i: Cardinal;
begin
  if containers.Count = 0 then exit;
  for i:= 0 to containers.Count-1 do
  begin
    if containers.Items[i].Status = STATUS_DOWNLOAD then
      containers.Items[i].thread.Terminate;
  end;
  Backup;
  MainForm.vtDownload.Repaint;
end;

procedure   TDownloadManager.FinishTask(const taskID: Cardinal);
begin
end;

// swap 2 task
function    TDownloadManager.Swap(const id1, id2: Cardinal): Boolean;
var
  tmp: TTaskThreadContainer;
begin
  if (id1 >= containers.Count) OR (id2 >= containers.Count) then exit(FALSE);
  tmp:= containers.Items[id1];
  containers.Items[id1]:= containers.Items[id2];
  containers.Items[id2]:= tmp;
  Result:= TRUE;
end;

// move a task down
function    TDownloadManager.MoveDown(const taskID: Cardinal): Boolean;
var
  tmp: TTaskThreadContainer;
begin
  if taskID > 0 then
  begin
    tmp:= containers.Items[taskID];
    containers.Items[taskID]:= containers.Items[taskID+1];
    containers.Items[taskID+1]:= tmp;
    Result:= TRUE;
  end
  else
    Result:= FALSE;
end;

// move a task up
function    TDownloadManager.MoveUp(const taskID: Cardinal): Boolean;
var
  tmp: TTaskThreadContainer;
begin
  if taskID < containers.Count-1 then
  begin
    tmp:= containers.Items[taskID];
    containers.Items[taskID]:= containers.Items[taskID-1];
    containers.Items[taskID-1]:= tmp;
    Result:= TRUE;
  end
  else
    Result:= FALSE;
end;

procedure   TDownloadManager.RemoveTask(const taskID: Cardinal);
begin
  if taskID >= containers.Count then exit;
  // check and stop any active thread
  if containers.Items[taskID].Status = STATUS_DOWNLOAD then
  begin
    containers.Items[taskID].thread.Terminate;
    containers.Items[taskID].Status:= STATUS_STOP;
  end
  else
  if containers.Items[taskID].Status = STATUS_WAIT then
  begin
    containers.Items[taskID].downloadInfo.Status:= stStop;
    containers.Items[taskID].Status:= STATUS_STOP;
  end;
  containers.Delete(taskID);
end;

procedure   TDownloadManager.RemoveAllFinishedTasks;
var
  i, j: Cardinal;
begin
  if containers.Count = 0 then exit;
  // remove
  i:= 0;
  repeat
    if containers.Items[i].Status = STATUS_FINISH then
    begin
      containers.Delete(i);
    end
    else
      Inc(i);
  until i >= containers.Count;
end;

end.

