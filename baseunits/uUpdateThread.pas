{
        File: uUpdateThread.pas
        License: GPLv2
        This unit is a part of Free Manga Downloader
}

unit uUpdateThread;

{$mode delphi}
{$DEFINE DOWNLOADER}
interface

uses
  Classes, SysUtils, Process, uData, uBaseUnit, uFMDThread;

type
  TUpdateMangaManagerThread = class;

  TUpdateMangaThread = class(TFMDThread)
  protected
    checkStyle        : Cardinal;
    names,
    links             : TStringList;
    threadCount,
    workPtr           : Cardinal;
    manager           : TUpdateMangaManagerThread;
    Info              : TMangaInformation;

    procedure   Execute; override;
    procedure   MainThreadUpdateNamesAndLinks;
  public
    constructor Create;
    destructor  Destroy; override;
  end;

  TUpdateMangaManagerThread = class(TFMDThread)
  protected
    procedure   Execute; override;
    {$IFNDEF DOWNLOADER}
    procedure   ConsoleReport;
    procedure   SaveCurrentDatabase;
    {$ENDIF}
    procedure   MainThreadShowGetting;
    procedure   RefreshList;
    procedure   DlgReport;
    procedure   getInfo(const limit, cs: Cardinal);
  public
    isFinishSearchingForNewManga,
    isDownloadFromServer,
    isDoneUpdateNecessary : Boolean;
    mainDataProcess,
    dataProcess           : TDataProcess;
    names,
    links,
    websites              : TStringList;
    S,
    website               : String;
    workPtr,
    directoryCount,
    // for fakku's doujinshi only
    directoryCount2,
    threadCount,
    numberOfThreads       : Cardinal;

    Infos                 : array of TMangaInformation;
    threads               : array of TUpdateMangaThread;
    threadStates          : array of Boolean;
    constructor Create;
    destructor  Destroy; override;
  end;

implementation

uses
  {$IFDEF DOWNLOADER}frmMain{$ELSE}mainunit{$ENDIF}, Dialogs;

// ----- TUpdateMangaThread -----

constructor TUpdateMangaThread.Create;
begin
  inherited Create(FALSE);
  names:= TStringList.Create;
  links:= TStringList.Create;
end;

destructor  TUpdateMangaThread.Destroy;
begin
  links.Free;
  names.Free;
  manager.threadStates[threadCount]:= FALSE;
  inherited Destroy;
end;

procedure   TUpdateMangaThread.MainThreadUpdateNamesAndLinks;
var
  i: Cardinal;
begin
  if names.Count = 0 then exit;
    for i:= 0 to names.Count - 1 do
    begin
      manager.names.Add(names.Strings[i]);
      manager.links.Add(links.Strings[i]);
    end;
end;

procedure   TUpdateMangaThread.Execute;
var
  i: Integer;
  s: String;
begin
  if Terminated then exit;
  while isSuspended do Sleep(16);
  case CheckStyle of
    CS_DIRECTORY_COUNT:
      begin
        {$IFDEF DOWNLOADER}
       // if manager.website = BATOTO_NAME then
       //   manager.directoryCount:= batotoLastDirectoryPage;
        {$ENDIF}
        if manager.website = WebsiteRoots[FAKKU_ID,0] then
        begin
          FAKKU_BROWSER:= FAKKU_MANGA_BROWSER;
          info.GetDirectoryPage(manager.directoryCount , manager.website);
          FAKKU_BROWSER:= FAKKU_DOUJINSHI_BROWSER;
          info.GetDirectoryPage(manager.directoryCount2, manager.website);
        end
        else
        if manager.website = WebsiteRoots[MANGAEDEN_ID,0] then
        begin
          MANGAEDEN_BROWSER:= MANGAEDEN_EN_BROWSER;
          info.GetDirectoryPage(manager.directoryCount , manager.website);
          MANGAEDEN_BROWSER:= MANGAEDEN_IT_BROWSER;
          info.GetDirectoryPage(manager.directoryCount2, manager.website);
        end
        else
        if manager.website = WebsiteRoots[PERVEDEN_ID,0] then
        begin
          PERVEDEN_BROWSER:= PERVEDEN_EN_BROWSER;
          info.GetDirectoryPage(manager.directoryCount , manager.website);
          PERVEDEN_BROWSER:= PERVEDEN_IT_BROWSER;
          info.GetDirectoryPage(manager.directoryCount2, manager.website);
        end
        else
          info.GetDirectoryPage(manager.directoryCount , manager.website);
        {$IFDEF DOWNLOADER}
       // if manager.website = BATOTO_NAME then
       //   {MainForm.}batotoLastDirectoryPage:= manager.directoryCount;
        {$ENDIF}
      end;
    CS_DIRECTORY_PAGE:
      begin
        if manager.website = WebsiteRoots[FAKKU_ID,0] then
        begin
          if Integer(workPtr-manager.directoryCount) >= 0 then
          begin
            FAKKU_BROWSER:= FAKKU_DOUJINSHI_BROWSER;
            Info.GetNameAndLink(names, links, manager.website, IntToStr(workPtr-manager.directoryCount));
          end
          else
          begin
            FAKKU_BROWSER:= FAKKU_MANGA_BROWSER;
            Info.GetNameAndLink(names, links, manager.website, IntToStr(workPtr));
          end;
        end
        else
        if manager.website = WebsiteRoots[MANGAEDEN_ID,0] then
        begin
          if Integer(workPtr-manager.directoryCount) >= 0 then
          begin
            MANGAEDEN_BROWSER:= MANGAEDEN_IT_BROWSER;
            Info.GetNameAndLink(names, links, manager.website, IntToStr(workPtr-manager.directoryCount));
          end
          else
          begin
            MANGAEDEN_BROWSER:= MANGAEDEN_EN_BROWSER;
            Info.GetNameAndLink(names, links, manager.website, IntToStr(workPtr));
          end;
        end
        else
        if manager.website = WebsiteRoots[PERVEDEN_ID,0] then
        begin
          if Integer(workPtr-manager.directoryCount) >= 0 then
          begin
            MANGAEDEN_BROWSER:= PERVEDEN_IT_BROWSER;
            Info.GetNameAndLink(names, links, manager.website, IntToStr(workPtr-manager.directoryCount));
          end
          else
          begin
            MANGAEDEN_BROWSER:= PERVEDEN_EN_BROWSER;
            Info.GetNameAndLink(names, links, manager.website, IntToStr(workPtr));
          end;
        end
        else
        begin
          Info.GetNameAndLink(names, links, manager.website, IntToStr(workPtr));
        end;
        Synchronize(MainThreadUpdateNamesAndLinks);
        // For Fakku and Pururin only, reduce the number of page we have to visit
        // in order to search for new series.
        {$IFDEF DOWNLOADER}
        if (manager.website = WebsiteRoots[FAKKU_ID,0]) OR
           (manager.website = WebsiteRoots[PURURIN_ID,0]) then
        begin
          // TODO: Need a better method to find duplicate string
          if (names.Count > 0) then
            if manager.dataProcess.Title.Find(names.Strings[0], i) then
              manager.isFinishSearchingForNewManga:= TRUE;
        end;
        {$ENDIF}
      end;
    CS_INFO:
      begin
        s:= manager.links[workPtr];
        Info.GetInfoFromURL(manager.website, manager.links[workPtr], {$IFDEF DOWNLOADER}5{$ELSE}0{$ENDIF});
     // {$IFNDEF DOWNLOADER}
        Info.AddInfoToDataWithoutBreak(manager.names[workPtr], manager.links[workPtr], manager.mainDataProcess);
     // {$ELSE}
     //   Info.AddInfoToData(manager.names[workPtr], manager.links[workPtr], manager.mainDataProcess);
     // {$ENDIF}
      end;
  end;
  manager.threadCount:= InterlockedDecrement(manager.threadCount);
end;

// ----- TUpdateMangaManagerThread -----

procedure   TUpdateMangaManagerThread.MainThreadShowGetting;
begin
  {$IFDEF DOWNLOADER}
  MainForm.sbMain.Panels[0].Text:= 'Getting list for ' + website + ' ...';
  {$ENDIF}
end;

constructor TUpdateMangaManagerThread.Create;
begin
  inherited Create(FALSE);
  websites   := TStringList.Create;
  names  := TStringList.Create;
  links  := TStringList.Create;
end;

destructor  TUpdateMangaManagerThread.Destroy;
var
  i: Cardinal;
begin
  websites.Free;
  names.Free;
  links.Free;
  for i:= 0 to numberOfThreads-1 do
    Infos[i].Free;
  SetLength(Infos, 0);
  SetLength(threads, 0);
  SetLength(threadStates, 0);
  {$IFDEF DOWNLOADER}
  MainForm.isUpdating:= FALSE;
  {$ENDIF}
  inherited Destroy;
end;

{$IFNDEF DOWNLOADER}
procedure   TUpdateMangaManagerThread.ConsoleReport;
begin
  MainForm.Memo1.Lines.Add(S);
end;

procedure   TUpdateMangaManagerThread.SaveCurrentDatabase;
begin
  mainDataProcess.SaveToFile(website);
  MainForm.Memo1.Lines.Clear;
end;
{$ENDIF}

procedure   TUpdateMangaManagerThread.RefreshList;
begin
  {$IFDEF DOWNLOADER}
  if MainForm.cbSelectManga.Items[MainForm.cbSelectManga.ItemIndex] = website then
  begin
    MainForm.dataProcess.RemoveFilter;
    MainForm.dataProcess.Free;
    MainForm.dataProcess:= TDataProcess.Create;
    MainForm.dataProcess.LoadFromFile(website);
    MainForm.vtMangaList.Clear;
    MainForm.vtMangaList.RootNodeCount:= MainForm.dataProcess.filterPos.Count;
    MainForm.lbMode.Caption:= Format(stModeAll, [MainForm.dataProcess.filterPos.Count]);
    MainForm.sbMain.Panels[0].Text:= '';
  end;
  {$ENDIF}
end;

procedure   TUpdateMangaManagerThread.DlgReport;
begin
  MessageDlg('', Format(stDlgNewManga, [website, links.Count]),
                 mtInformation, [mbYes], 0);
end;

procedure   TUpdateMangaManagerThread.getInfo(const limit, cs: Cardinal);
var
  j: Cardinal;
begin
  while (workPtr < limit) do
  begin
    // Finish search for series (for Puririn and Fakku only)
    {$IFDEF DOWNLOADER}
    if (cs = CS_DIRECTORY_PAGE) AND (isFinishSearchingForNewManga) then
    begin
      if (website = WebsiteRoots[FAKKU_ID,0]) then
      begin
        while threadCount > 0 do Sleep(96);
        if workPtr-directoryCount < 0 then
        begin
          workPtr:= directoryCount;
          isFinishSearchingForNewManga:= FALSE;
        end
        else
          workPtr:= $FFFFFFFF;
      end
      else
        workPtr:= $FFFFFFFF
    end
    else
    {$ENDIF}
    if (threadCount < numberOfThreads) then
      for j:= 0 to numberOfThreads-1 do
        if (NOT Assigned(threads[j])) OR (threadStates[j] = FALSE) then
        begin
          threadStates[j]:= TRUE;
          Sleep(32);
          Inc(threadCount);
          threads[j]:= TUpdateMangaThread.Create;
          threads[j].checkStyle:= cs;
          threads[j].manager:= self;
          threads[j].workPtr:= workPtr;
          threads[j].threadCount:= j;
          threads[j].Info:= Infos[j];
          Infos  [j].ClearInfo;
          threads[j].isSuspended:= FALSE;
          Inc(workPtr);
          S:= 'Updating list: '+website+'[T.'+IntToStr(j)+'; CS.'+IntToStr(cs)+'] '+IntToStr(workPtr)+' / '+IntToStr(limit);
          if cs = CS_INFO then
            S:= S+' "'+links.Strings[workPtr-1]+'"';
        {$IFNDEF DOWNLOADER}
          Synchronize(ConsoleReport);
          if (workPtr mod 100 = 0) AND (workPtr > 50) AND (cs = CS_INFO) AND (mainDataProcess.Data.Count > 5) then
            Synchronize(SaveCurrentDatabase);
        {$ELSE}
          MainForm.sbMain.Panels[0].Text:= S;
        {$ENDIF}
          break;
        end;
    Sleep(96);
  end;
end;

procedure   TUpdateMangaManagerThread.Execute;
var
  s      : String;
  i, j, k: Cardinal;
  syncProcess: TDataProcess;
begin
 // while NOT Terminated do
  begin
    while isSuspended do Sleep(16);
    if websites.Count = 0 then
      Terminate;
    SetLength(threads, numberOfThreads);
    SetLength(Infos, numberOfThreads);
    SetLength(threadStates, numberOfThreads);
    for i:= 0 to numberOfThreads-1 do
    begin
      Infos[i]:= TMangaInformation.Create;
      Infos[i].isGetByUpdater:= TRUE;
      threadStates[i]:= FALSE;
    end;

    {$IFDEF DOWNLOADER}
    if isDownloadFromServer then
    begin
      for i:= 0 to websites.Count-1 do
      begin
        website:= websites.Strings[i];
        Synchronize(MainThreadShowGetting);
        fmdRunAsAdmin('updater.exe', '1 '+GetMangaDatabaseURL(website), TRUE);
        Synchronize(RefreshList);
      end;
    end
    else
    {$ENDIF}
    for i:= 0 to websites.Count-1 do
    begin
      isFinishSearchingForNewManga:= FALSE;
      website:= websites.Strings[i];
      if website = WebsiteRoots[EATMANGA_ID,0] then
        numberOfThreads:= 1
      else
      if website = WebsiteRoots[SCANMANGA_ID,0] then
        numberOfThreads:= 2
      else
      if website = WebsiteRoots[FAKKU_ID,0] then
        numberOfThreads:= 3
      else
      if website = WebsiteRoots[PURURIN_ID,0] then
        numberOfThreads:= 3
      else
        numberOfThreads:= 4;

      {$IFDEF DOWNLOADER}
      while NOT FileExists(DATA_FOLDER+website+DATA_EXT) do
      begin
        Synchronize(MainThreadShowGetting);
        fmdRunAsAdmin('updater.exe', '1 '+GetMangaDatabaseURL(website), TRUE);
      end;
      {$ENDIF}

      dataProcess:= TDataProcess.Create;
      dataProcess.LoadFromFile(website);
      names.Clear;
      links.Clear;

      workPtr:= 0;
      getInfo(1, CS_DIRECTORY_COUNT);
      while threadCount > 0 do Sleep(100);

      workPtr:= 0;
      if (website = WebsiteRoots[FAKKU_ID,0]) OR
         (website = WebsiteRoots[MANGAEDEN_ID,0]) OR
         (website = WebsiteRoots[PERVEDEN_ID,0]) then
        getInfo(directoryCount+directoryCount2, CS_DIRECTORY_PAGE)
      else
        getInfo(directoryCount, CS_DIRECTORY_PAGE);
      while threadCount > 0 do Sleep(96);

      {$IFNDEF DOWNLOADER}
      names.SaveToFile(website+'_names.txt');
      links.SaveToFile(website+'_links.txt');

      names.Clear;
      links.Clear;

      names.LoadFromFile(website+'_names.txt');
      links.LoadFromFile(website+'_links.txt');
      {$ENDIF}

      mainDataProcess:= TDataProcess.Create;
      mainDataProcess.LoadFromFile(website);

      //
      j:= 0;
      while j < links.Count do
      begin
        if Find(links.Strings[j], mainDataProcess.Link, Integer(workPtr)) then
        begin
          links.Delete(j);
          names.Delete(j);
        end
        else
          Inc(j);
      end;

      // remove duplicate entries
      if links.Count > 0 then
      begin
        k:= 0;
        while k < links.Count do
        begin
          j:= k;
          while j < links.Count do
          begin
            if (k<>j) AND (CompareStr(links.Strings[k], links.Strings[j]) = 0) then
            begin
              links.Delete(j);
              names.Delete(j);
            end
            else
              Inc(j);
          end;
          Inc(k);
        end;
      end;

      // remove duplicate entries (current database)
      if mainDataProcess.Link.Count > 0 then
      begin
        k:= 0;
        while k < mainDataProcess.Link.Count do
        begin
          j:= k;
          while j < mainDataProcess.Link.Count do
          begin
            if (k<>j) AND (CompareStr(mainDataProcess.Link.Strings[k], mainDataProcess.Link.Strings[j]) = 0) then
            begin
              mainDataProcess.Link.Delete(j);
              mainDataProcess.Title.Delete(j);
              mainDataProcess.Data.Delete(j);
            end
            else
              Inc(j);
          end;
          Inc(k);
        end;
      end;

      if links.Count = 0 then
      begin
       // Synchronize(DlgReport);
        continue;
      end;

      if (website <> WebsiteRoots[TURKCRAFT_ID,0]) AND
         (website <> WebsiteRoots[MANGAFRAME_ID,0]) AND
         (website <> WebsiteRoots[MANGAVADISI_ID,0]) AND
         (website <> WebsiteRoots[KOMIKID_ID,0]) then
      begin
        workPtr:= 0;
        getInfo(links.Count, CS_INFO);
      end
      else
      begin
        for k:= 0 to links.Count-1 do
        begin
          {$IFDEF DOWNLOADER}
            mainDataProcess.Data.Add(
             RemoveStringBreaks(
             SetParams(
             [names.Strings[k],
             links.Strings[k],
             '',
             '',
             '',
             '',
             '',
             '0',
             IntToStr(GetCurrentJDN),
             '0'])));
          {$ELSE}
            mainDataProcess.Data.Add(
             RemoveStringBreaks(
             SetParams(
             [names.Strings[k],
             links.Strings[k],
             '',
             '',
             '',
             '',
             '',
             '0',
             '0',
             '0'])));
          {$ENDIF}
        end;
      end;

      Sleep(100);
      while threadCount > 0 do Sleep(100);

      // sync data based on existing sites
      if  (mainDataProcess.Data.Count > 0) AND
          (sitesWithoutInformation(website)) AND
         ((FileExists(DATA_FOLDER + WebsiteRoots[ANIMEA_ID,0] + DATA_EXT)) OR
          (FileExists(DATA_FOLDER + WebsiteRoots[MANGAPARK_ID,0] + DATA_EXT))) then
      begin
        syncProcess:= TDataProcess.Create;
        if FileExists(DATA_FOLDER + WebsiteRoots[MANGAPARK_ID,0] + DATA_EXT) then
          syncProcess.LoadFromFile(WebsiteRoots[MANGAPARK_ID,0])
        else
        if FileExists(DATA_FOLDER + WebsiteRoots[BATOTO_ID,0] + DATA_EXT) then
          syncProcess.LoadFromFile(WebsiteRoots[BATOTO_ID,0])
        else
        if FileExists(DATA_FOLDER + WebsiteRoots[MANGAGO_ID,0] + DATA_EXT) then
          syncProcess.LoadFromFile(WebsiteRoots[MANGAGO_ID,0])
        else
        if FileExists(DATA_FOLDER + WebsiteRoots[ANIMEA_ID,0] + DATA_EXT) then
          syncProcess.LoadFromFile(WebsiteRoots[ANIMEA_ID,0]);

        // brute force ...
        for k:= 0 to mainDataProcess.Data.Count-1 do
        begin
          for j:= 0 to syncProcess.Data.Count-1 do
            if SameText(mainDataProcess.Param[k, DATA_PARAM_NAME], syncProcess.Param[j, DATA_PARAM_NAME]) then
            begin
              if (website = WebsiteRoots[MANGASTREAM_ID,0]) OR
                 (website = WebsiteRoots[S2SCAN_ID,0]) then
                s:= syncProcess.Param[j, DATA_PARAM_SUMMARY]
              else
                s:= mainDataProcess.Param[k, DATA_PARAM_SUMMARY];
              mainDataProcess.Data.Strings[k]:=
                RemoveStringBreaks(
                  mainDataProcess.Param[k, DATA_PARAM_NAME]      +SEPERATOR+
                  mainDataProcess.Param[k, DATA_PARAM_LINK]      +SEPERATOR+
                  syncProcess    .Param[j, DATA_PARAM_AUTHORS]   +SEPERATOR+
                  syncProcess    .Param[j, DATA_PARAM_ARTISTS]   +SEPERATOR+
                  syncProcess    .Param[j, DATA_PARAM_GENRES]    +SEPERATOR+
                  mainDataProcess.Param[k, DATA_PARAM_STATUS]    +SEPERATOR+
                  s+SEPERATOR+
                  mainDataProcess.Param[k, DATA_PARAM_NUMCHAPTER]+SEPERATOR+
                  mainDataProcess.Param[k, DATA_PARAM_JDN]       +SEPERATOR+
                  mainDataProcess.Param[k, DATA_PARAM_READ]      +SEPERATOR);
              break;
            end;
        end;

        syncProcess.Free;
      end;

      mainDataProcess.SaveToFile(website);
      mainDataProcess.Free;

      dataProcess.Free;
      {$IFDEF DOWNLOADER}
      Synchronize(RefreshList);
      {$ENDIF}
    end;
  {$IFNDEF DOWNLOADER}
    S:= 'Saving to '+website+'.dat ...';
    Synchronize(ConsoleReport);
    S:= 'Done.';
    Synchronize(ConsoleReport);
  {$ELSE}
   // Synchronize(DlgReport);
    MainForm.sbMain.Panels[0].Text:= '';
  {$ENDIF}
   // Synchronize(DlgReport);
  end;
end;

end.

