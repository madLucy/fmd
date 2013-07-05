{
        File: baseunit.pas
        License: GPLv2
        This unit is a part of Free Manga Downloader
}

unit baseunit;

{$MODE DELPHI}

interface

uses SysUtils, Classes, HTTPSend, graphics, genericlib, IniFiles;

const
  JPG_HEADER: array[0..2] of Byte = ($FF, $D8, $FF);
  GIF_HEADER: array[0..2] of Byte = ($47, $49, $46);
  PNG_HEADER: array[0..2] of Byte = ($89, $50, $4E);
  CS_DIRECTORY_COUNT = 0;
  CS_DIRECTORY_PAGE  = 1;
  CS_INFO            = 2;
  CS_GETPAGENUMBER   = 3;
  CS_GETPAGELINK     = 4;
  CS_DOWNLOAD        = 5;

  DATA_PARAM_NAME       = 0;
  DATA_PARAM_LINK       = 1;
  DATA_PARAM_AUTHORS    = 2;
  DATA_PARAM_ARTISTS    = 3;
  DATA_PARAM_GENRES     = 4;
  DATA_PARAM_STATUS     = 5;
  DATA_PARAM_SUMMARY    = 6;
  DATA_PARAM_NUMCHAPTER = 7;
  DATA_PARAM_JDN        = 8;
  DATA_PARAM_READ       = 9;

  FILTER_HIDE           = 0;
  FILTER_SHOW           = 1;

  Genre: array [0..37] of String =
    ('Action'       , 'Adult'        , 'Adventure'    , 'Comedy',
     'Doujinshi'    , 'Drama'        , 'Ecchi'        , 'Fantasy',
     'Gender Bender', 'Harem'        , 'Hentai'       , 'Historical',
     'Horror'       , 'Josei'        , 'Lolicon'      , 'Martial Arts',
     'Mature'       , 'Mecha'        , 'Musical'      , 'Mystery',
     'Psychological', 'Romance'      , 'School Life'  , 'Sci-fi',
     'Seinen'       , 'Shotacon'     , 'Shoujo'       , 'Shoujo Ai',
     'Shounen'      , 'Shounen Ai'   , 'Slice of Life', 'Smut',
     'Sports'       , 'Supernatural' , 'Traged'       , 'Yaoi',
     'Yuri'         , 'Webtoons');

  GenreMeaning: array [0..37] of String =
    ('A work typically depicting fighting, violence, chaos, and fast paced motion.',
     'Contains content that is suitable only for adults. Titles in this category may include prolonged scenes of intense violence and/or graphic sexual content and nudity.',
     'If a character in the story goes on a trip or along that line, your best bet is that it is an adventure manga. Otherwise, it''s up to your personal prejudice on this case.',
     'A dramatic work that is light and often humorous or satirical in tone and that usually contains a happy resolution of the thematic conflict.',
     'Fan based work inpspired by official manga/anime.',
     'A work meant to bring on an emotional response, such as instilling sadness or tension.',
     'Possibly the line between hentai and non-hentai, ecchi usually refers to fanservice put in to attract a certain group of fans.',
     'Anything that involves, but not limited to, magic, dream world, and fairy tales.',
     'Girls dressing up as guys, guys dressing up as girls.. Guys turning into girls, girls turning into guys.. I think you get the picture.',
     'A series involving one male character and many female characters (usually attracted to the male character). A Reverse Harem is when the genders are reversed.',
     '',
     'Having to do with old or ancient times.',
     'A painful emotion of fear, dread, and abhorrence; a shuddering with terror and detestation; the feeling inspired by something frightful and shocking.',
     'Literally "Woman". Targets women 18-30. Female equivalent to seinen. Unlike shoujo the romance is more realistic and less idealized. The storytelling is more explicit and mature.',
     'Representing a sexual attraction to young or under-age girls.',
     'As the name suggests, anything martial arts related. Any of several arts of combat or self-defense, such as aikido, karate, judo, or tae kwon do, kendo, fencing, and so on and so forth.',
     'Contains subject matter which may be too extreme for people under the age of 17. Titles in this category may contain intense violence, blood and gore, sexual content and/or strong language.',
     'A work involving and usually concentrating on all types of large robotic machines.',
     '',
     'Usually an unexplained event occurs, and the main protagonist attempts to find out what caused it.',
     'Usually deals with the philosophy of a state of mind, in most cases detailing abnormal psychology.',
     'Any love related story. We will define love as between man and woman in this case. Other than that, it is up to your own imagination of what love is.',
     'Having a major setting of the story deal with some type of school.',
     'Short for science fiction, these works involve twists on technology and other science related phenomena which are contrary or stretches of the modern day scientific world.',
     'From Google: '+#10#13+'Seinen means ''young Man.'' Manga and anime that specifically targets young adult males around the ages of 18 to 25 are seinen titles. The stories in seinen works appeal to university students and those in the working world. Typically the story lines deal with the issues of adulthood.',
     'Representing a sexual attraction to young or under-age boys.',
     'A work intended and primarily written for females. Usually involves a lot of romance and strong character development.',
     'Often synonymous with yuri, this can be thought of as somewhat less extreme. "Girl''s Love", so to speak.',
     'A work intended and primarily written for males. These works usually involve fighting and/or violence.',
     'Often synonymous with yaoi, this can be thought of as somewhat less extreme. "Boy''s Love", so to speak.',
     'As the name suggests, this genre represents day-to-day tribulations of one/many character(s). These challenges/events could technically happen in real life and are often -if not all the time- set in the present timeline in a world that mirrors our own.',
     'Deals with series that are considered profane or offensive, particularly with regards to sexual content.',
     'As the name suggests, anything sports related. Baseball, basketball, hockey, soccer, golf, and racing just to name a few.',
     'Usually entails amazing and unexplained powers or events which defy the laws of physics.',
     'Contains events resulting in great loss and misfortune.',
     'This work usually involves intimate relationships between men.',
     'This work usually involves intimate relationships between women.',
     '');

  Symbols: array [0..8] of Char =
    ('\', '/', ':', '*', '?', '"', '<', '>', '|');

  {$IFDEF WIN32}
  DEFAULT_PATH  = 'c:\downloads';
  {$ELSE}
  DEFAULT_PATH  = '/downloads';
  {$ENDIF}

  README_FILE       = 'readme.rtf';

  WORK_FOLDER       = 'works/';
  WORK_FILE         = 'works.ini';

  FAVORITES_FILE    = 'favorites.ini';
  IMAGE_FOLDER      = 'images/';
  DATA_FOLDER       = 'data/';
  DATA_EXT          = '.dat';
  CONFIG_FOLDER     = 'config/';
  CONFIG_FILE       = 'config.ini';
  UPDATE_FILE       = 'updates.ini';
  MANGALISTINI_FILE = 'mangalist.ini';
  LANGUAGE_FILE     = 'languages.ini';
  LOG_FILE          = 'changelog.txt';

  OPTION_MANGALIST = 0;
  OPTION_RECONNECT = 1;

  STATUS_STOP      = 0;
  STATUS_WAIT      = 1;
  STATUS_PREPARE   = 2;
  STATUS_DOWNLOAD  = 3;
  STATUS_FINISH    = 4;

  DO_EXIT_FMD      = 1;
  DO_TURNOFF       = 2;

  NO_ERROR              = 0;
  NET_PROBLEM           = 1;
  INFORMATION_NOT_FOUND = 2;

  ANIMEA_NAME       = 'AnimeA';       ANIMEA_ID      = 0;
  MANGAHERE_NAME    = 'MangaHere';    MANGAHERE_ID   = 1;
  MANGAINN_NAME     = 'MangaInn';     MANGAINN_ID    = 2;
  OURMANGA_NAME     = 'OurManga';     OURMANGA_ID    = 3;
  KISSMANGA_NAME    = 'KissManga';    KISSMANGA_ID   = 4;
  BATOTO_NAME       = 'Batoto';       BATOTO_ID      = 5;
  MANGA24H_NAME     = 'Manga24h';     MANGA24H_ID    = 6;
  VNSHARING_NAME    = 'VnSharing';    VNSHARING_ID   = 7;
  HENTAI2READ_NAME  = 'Hentai2Read';  HENTAI2READ_ID = 8;
  FAKKU_NAME        = 'Fakku';        FAKKU_ID       = 9;
  TRUYEN18_NAME     = 'Truyen18';     TRUYEN18_ID    = 10;
  MANGAREADER_NAME  = 'MangaReader';  MANGAREADER_ID = 11;
  MANGAPARK_NAME    = 'MangaPark';    MANGAPARK_ID   = 12;
  GEHENTAI_NAME     = 'E-Hentai';     GEHENTAI_ID    = 13;
  MANGAFOX_NAME     = 'MangaFox';     MANGAFOX_ID    = 14;
  MANGATRADERS_NAME = 'MangaTraders'; MANGATRADERS_ID= 15;
  MANGASTREAM_NAME  = 'MangaStream';  MANGASTREAM_ID = 16;
  MANGAEDEN_NAME    = 'MangaEden';    MANGAEDEN_ID   = 17;
  PERVEDEN_NAME     = 'PervEden';     PERVEDEN_ID    = 18;
  TRUYENTRANHTUAN_NAME = 'TruyenTranhTuan'; TRUYENTRANHTUAN_ID = 19;
  TURKCRAFT_NAME    = 'Turkcraft';    TURKCRAFT_ID   = 20;
  MANGAVADISI_NAME  = 'MangaVadisi';  MANGAVADISI_ID = 21;
  EATMANGA_NAME     = 'EatManga';     EATMANGA_ID    = 22;
  BLOGTRUYEN_NAME   = 'BlogTruyen';   BLOGTRUYEN_ID  = 23;
  MANGAFRAME_NAME   = 'MangaFrame';   MANGAFRAME_ID  = 24;
  STARKANA_NAME     = 'Starkana';     STARKANA_ID    = 25;

  DEFAULT_LIST = ANIMEA_NAME+'!%~'+MANGAFOX_NAME+'!%~'+MANGAHERE_NAME+'!%~'+MANGAINN_NAME+'!%~'+MANGAREADER_NAME+'!%~';

var
  // cbOptionLetFMDDoItemIndex
  cbOptionLetFMDDoItemIndex: Cardinal = 0;

  Revision         : Cardinal;
  // only for batoto: the directory page from the last time we check the site
  batotoLastDirectoryPage: Cardinal = 289;
  currentJDN       : Cardinal;
  isChangeDirectory: Boolean = FALSE;

  currentWebsite,
  stModeAll,
  stModeFilter,

  stCompressing,
  stPreparing,
  stDownloading,
  stWait,
  stStop,
  stFinish: String;

  Host  : String = '';
  Port  : String = '';
  User  : String = '';
  Pass  : String = '';
  oldDir: String;
  // EN: Param seperator
  // VI: Ký tự dùng để chia cắt param trong dữ liệu
  SEPERATOR: String = '!%~';

  ANIMEA_ROOT   : String = 'http://manga.animea.net';
  ANIMEA_BROWSER: String = '/browse.html?page=';
  ANIMEA_SKIP   : String = '?skip=1';

  MANGAHERE_ROOT   : String = 'http://www.mangahere.com';
  MANGAHERE_BROWSER: String = '/mangalist/';

  MANGAINN_ROOT   : String = 'http://www.mangainn.com';
  MANGAINN_BROWSER: String = '/mangalist/';

  OURMANGA_ROOT   : String = 'http://www.ourmanga.com';
  OURMANGA_BROWSER: String = '/directory/';

  KISSMANGA_ROOT   : String = 'http://kissmanga.com';
  KISSMANGA_BROWSER: String = '/MangaList';

  BATOTO_ROOT      : String = 'http://www.batoto.net';
  BATOTO_BROWSER   : String = '/search';

  MANGA24H_ROOT   : String = 'http://manga24h.com';
  MANGA24H_BROWSER: String = '/manga/update/page/';

  VNSHARING_ROOT   : String = 'http://truyen.vnsharing.net';
  VNSHARING_BROWSER: String = '/DanhSach';

  HENTAI2READ_ROOT   : String = 'http://hentai2read.com';
  HENTAI2READ_MROOT  : String = 'http://m.hentai2read.com';
  HENTAI2READ_BROWSER: String = '/hentai-list/all/any/name-az/';

  FAKKU_ROOT             : String = 'http://www.fakku.net';
  FAKKU_BROWSER          : String = '/manga/newest';
  FAKKU_MANGA_BROWSER    : String = '/manga/newest';
  FAKKU_DOUJINSHI_BROWSER: String = '/doujinshi/newest';

  TRUYEN18_ROOT   : String = 'http://www.truyen18.org';
  TRUYEN18_BROWSER: String = '/moi-dang/danhsach';

  MANGAREADER_ROOT   : String = 'http://www.mangareader.net';
  MANGAREADER_BROWSER: String = '/alphabetical';

  MANGAPARK_ROOT   : String = 'http://www.mangapark.com';
  MANGAPARK_BROWSER: String = '/list/';

  GEHENTAI_ROOT   : String = 'http://g.e-hentai.org';
  GEHENTAI_BROWSER: String = '&f_doujinshi=on&advsearch=1&f_search=Search+Keywords&f_srdd=2&f_sname=on&f_stags=on&f_apply=Apply+Filter';

  MANGAFOX_ROOT   : String = 'http://mangafox.me';
  MANGAFOX_BROWSER: String = '/directory/';

  MANGATRADERS_ROOT   : String = 'http://www.mangatraders.com';
  MANGATRADERS_BROWSER: String = '/manga/serieslist/';

  MANGASTREAM_ROOT   : String = 'http://mangastream.com';
  MANGASTREAM_BROWSER: String = '/manga';

  MANGAEDEN_ROOT      : String = 'http://www.mangaeden.com';
  MANGAEDEN_BROWSER   : String = '/en-directory/';
  MANGAEDEN_EN_BROWSER: String = '/en-directory/';
  MANGAEDEN_IT_BROWSER: String = '/it-directory/';

  PERVEDEN_ROOT      : String = 'http://www.perveden.com';
  PERVEDEN_BROWSER   : String = '/en-directory/';
  PERVEDEN_EN_BROWSER: String = '/en-directory/';
  PERVEDEN_IT_BROWSER: String = '/it-directory/';

  TRUYENTRANHTUAN_ROOT   : String = 'http://truyentranhtuan.com';
  TRUYENTRANHTUAN_BROWSER: String = '/danh-sach-truyen/';

  TURKCRAFT_ROOT   : String = 'http://turkcraft.com';
  TURKCRAFT_BROWSER: String = '/';

  MANGAVADISI_ROOT   : String = 'http://www.mangavadisi.net';
  MANGAVADISI_BROWSER: String = '/hemenoku/';

  MANGAFRAME_ROOT   : String = 'http://www.mngfrm.com';
  MANGAFRAME_BROWSER: String = '/Okuyucu/reader/list/';

  EATMANGA_ROOT   : String = 'http://eatmanga.com';
  EATMANGA_BROWSER: String = '/Manga-Scan/';

  STARKANA_ROOT   : String = 'http://starkana.com';
  STARKANA_BROWSER: String = '/manga/list';

  BLOGTRUYEN_ROOT      : String = 'http://blogtruyen.com';
  BLOGTRUYEN_BROWSER   : String = '/danhsach/tatca';
  BLOGTRUYEN_JS_BROWSER: String = '/partialDanhSach/listtruyen/';
  BLOGTRUYEN_POST_FORM : String = 'listOrCate=list&orderBy=title&key=tatca&page=';

  UPDATE_URL      : String = 'http://akarin.byethost5.com/fmd/';

  OptionAutoCheckMinutes,
  // en: dialog messages
  // vi: nội dung hộp thoại
  infoCustomGenres,
  infoName,
  infoAuthors,
  infoArtists,
  infoGenres,
  infoStatus,
  infoSummary,
  infoLink ,

  // this is for erasing the "Search..." message
  stSearch,

  stDownloadManga,
  stDownloadStatus,
  stDownloadProgress,
  stDownloadWebsite,
  stDownloadSaveto,
  stDownloadAdded,
  stFavoritesCurrentChapter,

  stFavoritesCheck,
  stFavoritesChecking,

  stUpdaterCheck,

  stDlgUpdaterVersionRequire,
  stDlgUpdaterIsRunning,
  stDlgLatestVersion,
  stDlgNewVersion,
  stDlgURLNotSupport,
  stDldMangaListSelect,
  stDlgUpdateAlreadyRunning,
  stDlgNewManga,
  stDlgQuit,
  stDlgRemoveTask,
  stDlgRemoveFinishTasks,
  stDlgTypeInNewChapter,
  stDlgTypeInNewSavePath,
  stDlgCannotGetMangaInfo,
  stDlgFavoritesIsRunning,
  stDlgNoNewChapter,
  stDlgHasNewChapter,
  stDlgRemoveCompletedManga,
  stDlgUpdaterWantToUpdateDB,
  stDlgUpdaterCannotConnectToServer: String;

  OptionCheckMinutes: Cardinal = 0;
  OptionPDFQuality  : Cardinal = 95;
  OptionMaxRetry    : Cardinal = 0;

  OptionBatotoUseIEChecked: Boolean = TRUE;
  OptionAutoNumberChapterChecked: Boolean = TRUE;
  OptionAutoCheckFavStartup: Boolean = FALSE;

type
  TMemory = Pointer;

  PMangaListItem = ^TMangaListItem;
  TMangaListItem = record
    Text: String;
  end;

  PMangaInfo = ^TMangaInfo;
  TMangaInfo = record
    url,
    title,
    link,
    website,
    coverLink,
    authors,
    artists,
    genres,
    status,
    summary     : String;
    numChapter  : Cardinal;
    chapterName,
    chapterLinks: TStringList;
  end;

  PDownloadInfo = ^TDownloadInfo;
  TDownloadInfo = record
    title,
    Status,
    Progress,
    Website,
    SaveTo,
    dateTime : String;
    iProgress: Integer;
  end;

  PFavoriteInfo = ^TFavoriteInfo;
  TFavoriteInfo = record
    title,
    downloadedChapterList,
    currentChapter,
    Website,
    SaveTo,
    Link     : String;
  end;

  TCardinalList = TGenericList<Cardinal>;
  TByteList   = TGenericList<Byte>;

  TDownloadPageThread = class(TThread)
  protected
    procedure Execute; override;
  public
    isSuccess,
    isDone: Boolean;
    Retry : Cardinal;
    URL,
    Path  : String;
    constructor Create(CreateSuspended: Boolean);
  end;

function  UnicodeRemove(const S: String): String;
function  CheckRedirect(const HTTP: THTTPSend): String;
function  CorrectFile(const APath: String): String;
function  CorrectFilePath(const APath: String): String;
function  CorrectURL(const URL: String): String;
procedure CheckPath(const S: String);

function  GetMangaSiteID(const name: String): Cardinal;
function  GetMangaSiteName(const ID: Cardinal): String;
function  GetMangaDatabaseURL(const name: String): String;

function  RemoveSymbols(const input: String): String;

// EN: Get substring from source
// VI: Lấy chuỗi con từ chuỗi mẹ
function  GetString(const source, sStart, sEnd: String): String;

function  Find(const S: String; var List: TStringList; out index: Integer): Boolean;

// EN: Get param from input
// VI: Lấy param từ input
procedure GetParams(const output: TStringList; input: String); overload;
procedure GetParams(var output: TCardinalList; input: String); overload;
// EN: Set param from input
// VI: Cài param từ input
function  SetParams(input: TObject): String; overload;
function  SetParams(const input: array of String): String; overload;

procedure CustomGenres(var output: TStringList; input: String);

function  FixPath(const path: String): String;
function  GetLastDir(const path: String): String;
function  FixLastDir(const path: String): String;
function  StringFilter(const source: String): String;
function  HTMLEntitiesFilter(const source: String): String;
function  StringBreaks(const source: String): String;
function  RemoveStringBreaks(const source: String): String;

function  PrepareSummaryForHint(const source: String):  String;

// EN: Get HTML source code from a URL
// VI: Lấy webcode từ 1 URL
function  gehGetPage(var output: TObject; URL: String; const Reconnect: Cardinal; const lURL: String = ''): Boolean;
function  bttGetPage(var output: TObject; URL: String; const Reconnect: Cardinal): Boolean;
function  GetPage(var output: TObject; URL: String; const Reconnect: Cardinal; const isByPassHTTP: Boolean = FALSE): Boolean;
function  SavePage(URL: String;  const Path, name: String; const Reconnect: Cardinal): Boolean;

procedure QuickSortData(var merge: TStringList);
procedure QuickSortDataWithWebID(var merge: TStringList; const webIDList: TByteList);

function  GetCurrentJDN: LongInt;

{function  ConvertInt32ToStr(const aValue: Cardinal)  : String;
function  ConvertStrToInt32(const aStr  : String): Cardinal;}
procedure TransferMangaInfo(var dest: TMangaInfo; const source: TMangaInfo);

// cross platform funcs

function  fmdGetTempPath: String;
function  fmdGetTickCount: Cardinal;
procedure fmdPowerOff;

implementation

uses FileUtil{$IFDEF WINDOWS}, Windows{$ENDIF}, Synacode;

{$IFDEF WINDOWS}

// thanks Leledumbo for the code
const
  SE_CREATE_TOKEN_NAME = 'SeCreateTokenPrivilege';
  SE_ASSIGNPRIMARYTOKEN_NAME = 'SeAssignPrimaryTokenPrivilege';
  SE_LOCK_MEMORY_NAME = 'SeLockMemoryPrivilege';
  SE_INCREASE_QUOTA_NAME = 'SeIncreaseQuotaPrivilege';
  SE_UNSOLICITED_INPUT_NAME = 'SeUnsolicitedInputPrivilege';
  SE_MACHINE_ACCOUNT_NAME = 'SeMachineAccountPrivilege';
  SE_TCB_NAME = 'SeTcbPrivilege';
  SE_SECURITY_NAME = 'SeSecurityPrivilege';
  SE_TAKE_OWNERSHIP_NAME = 'SeTakeOwnershipPrivilege';
  SE_LOAD_DRIVER_NAME = 'SeLoadDriverPrivilege';
  SE_SYSTEM_PROFILE_NAME = 'SeSystemProfilePrivilege';
  SE_SYSTEMTIME_NAME = 'SeSystemtimePrivilege';
  SE_PROF_SINGLE_PROCESS_NAME = 'SeProfileSingleProcessPrivilege';
  SE_INC_BASE_PRIORITY_NAME = 'SeIncreaseBasePriorityPrivilege';
  SE_CREATE_PAGEFILE_NAME = 'SeCreatePagefilePrivilege';
  SE_CREATE_PERMANENT_NAME = 'SeCreatePermanentPrivilege';
  SE_BACKUP_NAME = 'SeBackupPrivilege';
  SE_RESTORE_NAME = 'SeRestorePrivilege';
  SE_SHUTDOWN_NAME = 'SeShutdownPrivilege';
  SE_DEBUG_NAME = 'SeDebugPrivilege';
  SE_AUDIT_NAME = 'SeAuditPrivilege';
  SE_SYSTEM_ENVIRONMENT_NAME = 'SeSystemEnvironmentPrivilege';
  SE_CHANGE_NOTIFY_NAME = 'SeChangeNotifyPrivilege';
  SE_REMOTE_SHUTDOWN_NAME = 'SeRemoteShutdownPrivilege';
  SE_UNDOCK_NAME = 'SeUndockPrivilege';
  SE_SYNC_AGENT_NAME = 'SeSyncAgentPrivilege';
  SE_ENABLE_DELEGATION_NAME = 'SeEnableDelegationPrivilege';
  SE_MANAGE_VOLUME_NAME = 'SeManageVolumePrivilege';

function SetSuspendState(hibernate, forcecritical, disablewakeevent: Boolean): Boolean; stdcall; external 'powrprof.dll' name 'SetSuspendState';
function IsHibernateAllowed: Boolean; stdcall; external 'powrprof.dll' name 'IsPwrHibernateAllowed';
function IsPwrSuspendAllowed: Boolean; stdcall; external 'powrprof.dll' name 'IsPwrSuspendAllowed';
function IsPwrShutdownAllowed: Boolean; stdcall; external 'powrprof.dll' name 'IsPwrShutdownAllowed';
function LockWorkStation: Boolean; stdcall; external 'user32.dll' name 'LockWorkStation';

function NTSetPrivilege(sPrivilege: string; bEnabled: Boolean): Boolean;
var
  hToken: THandle;
  TokenPriv: TOKEN_PRIVILEGES;
  PrevTokenPriv: TOKEN_PRIVILEGES;
  ReturnLength: Cardinal;
begin
  Result := True;
  // Only for Windows NT/2000/XP and later.
  if not (Win32Platform = VER_PLATFORM_WIN32_NT) then Exit;
  Result := False;

  // obtain the processes token
  if OpenProcessToken(GetCurrentProcess(),
    TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY, hToken) then
  begin
    try
      // Get the locally unique identifier (LUID) .
      if LookupPrivilegeValue(nil, PChar(sPrivilege),
        TokenPriv.Privileges[0].Luid) then
      begin
        TokenPriv.PrivilegeCount := 1; // one privilege to set

        case bEnabled of
          True: TokenPriv.Privileges[0].Attributes  := SE_PRIVILEGE_ENABLED;
          False: TokenPriv.Privileges[0].Attributes := 0;
        end;

        ReturnLength := 0; // replaces a var parameter
        PrevTokenPriv := TokenPriv;

        // enable or disable the privilege

        AdjustTokenPrivileges(hToken, False, TokenPriv, SizeOf(PrevTokenPriv),
          PrevTokenPriv, ReturnLength);
      end;
    finally
      CloseHandle(hToken);
    end;
  end;
  // test the return value of AdjustTokenPrivileges.
  Result := GetLastError = ERROR_SUCCESS;
  if not Result then
    raise Exception.Create(SysErrorMessage(GetLastError));
end;
{$ENDIF}

function  UnicodeRemove(const S: String): String;
var i: Cardinal;
begin
 // if doRemoveName then
    Result:= S;
 { else
  begin
    result:= '';
    exit;
  end; }
 // if NOT doRemoveUnicode then exit;
  for i:= 1 to Length(Result) do
  begin
    if (Byte(Result[i])<31) OR (Byte(Result[i])>127) then
    begin
      Delete(Result, i, 1);
      Insert('_', Result, i);
    end;
  end;
end;

function  CorrectFile(const APath: String): String;
var I: Integer;
begin
  if APath = '' then exit('');
  Result:= APath;
  for I:=1 to Length(Result) do
    if Result[I]= '\' then
      Result[I]:= '/';
  if Result[Length(Result)]<>'/' then
    Result:= Result + '/';
 // Result:= StringReplace(Result, '\', '/', [rfReplaceAll]);
  while system.Pos('//', Result) > 0 do
    Result:= StringReplace(Result, '//', '/', []);
end;

function  CorrectURL(const URL: String): String;
begin
  Result:= StringReplace(URL, ' ', '%20', [rfReplaceAll]);
end;

function  CorrectFilePath(const APath: String): String;
var I: Integer;
begin
  Result:= APath;
  for I:=1 to Length(Result) do
    if Result[I]= '\' then
      Result[I]:='/';
  if Length(Result)<>0 then
    if Result[Length(Result)]<>'/' then
      Result:= Result+'/';
end;

// took from an old project - maybe bad code
procedure CheckPath(const S: String);
var
    wS,
    lcS,
    lcS2: String;
    i,
    j   : Word;
begin
  wS:= s;
  lcS2:= '';
  if wS[2]<>':' then
  begin
    {$IFDEF WIN32}
    lcS2:= CorrectFile(oldDir);
    {$ELSE}
    lcS2:= '';
    {$ENDIF}
    Insert('/', wS, 1);
  end
  else
  begin
    if Length(wS)=2 then
      wS:= wS+'/';
  end;
  for i:= 1 to Length(wS) do
  begin
    lcS2:= lcS2+wS[i];
    if (wS[i]='/') AND ((wS[i+1]<>'/') OR (wS[i+1]<>' ')) AND
       (i<Length(wS)) then
    begin
      j:= i+1;
      lcS:= '';
      repeat
        lcS:= lcS+wS[j];
        Inc(j);
      until wS[j]='/';
      if NOT DirectoryExistsUTF8(lcS2+lcS) then
      begin
        CreateDirUTF8(lcS2+lcS);
      end;
    end;
  end;
 // ForceDirectoriesUTF8(wS);
  SetCurrentDirUTF8(oldDir);
 // Delete(wS, 1, 1);
end;

function  GetMangaSiteID(const name: String): Cardinal;
begin
  if name = ANIMEA_NAME then Result:= ANIMEA_ID
  else
  if name = MANGAHERE_NAME then Result:= MANGAHERE_ID
  else
  if name = MANGAINN_NAME then Result:= MANGAINN_ID
  else
  if name = OURMANGA_NAME then Result:= OURMANGA_ID
  else
  if name = KISSMANGA_NAME then Result:= KISSMANGA_ID
  else
  if name = BATOTO_NAME then Result:= BATOTO_ID
  else
  if name = MANGA24H_NAME then Result:= MANGA24H_ID
  else
  if name = VNSHARING_NAME then Result:= VNSHARING_ID
  else
  if name = HENTAI2READ_NAME then Result:= HENTAI2READ_ID
  else
  if name = FAKKU_NAME then Result:= FAKKU_ID
  else
  if name = MANGAREADER_NAME then Result:= MANGAREADER_ID
  else
  if name = MANGAPARK_NAME then Result:= MANGAPARK_ID
  else
  if name = GEHENTAI_NAME then Result:= GEHENTAI_ID
  else
  if name = MANGAFOX_NAME then Result:= MANGAFOX_ID
  else
  if name = MANGATRADERS_NAME then Result:= MANGATRADERS_ID
  else
  if name = MANGASTREAM_NAME then Result:= MANGASTREAM_ID
  else
  if name = MANGAEDEN_NAME then Result:= MANGAEDEN_ID
  else
  if name = PERVEDEN_NAME then Result:= PERVEDEN_ID
  else
  if name = TRUYENTRANHTUAN_NAME then Result:= TRUYENTRANHTUAN_ID
  else
  if name = TURKCRAFT_NAME then Result:= TURKCRAFT_ID
  else
  if name = MANGAVADISI_NAME then Result:= MANGAVADISI_ID
  else
  if name = EATMANGA_NAME then Result:= EATMANGA_ID
  else
  if name = BLOGTRUYEN_NAME then Result:= BLOGTRUYEN_ID
  else
  if name = MANGAFRAME_NAME then Result:= MANGAFRAME_ID
  else
  if name = STARKANA_NAME then Result:= STARKANA_ID;
end;

function  GetMangaSiteName(const ID: Cardinal): String;
begin
  if ID = ANIMEA_ID then Result:= ANIMEA_NAME
  else
  if ID = MANGAHERE_ID then Result:= MANGAHERE_NAME
  else
  if ID = MANGAINN_ID then Result:= MANGAINN_NAME
  else
  if ID = OURMANGA_ID then Result:= OURMANGA_NAME
  else
  if ID = KISSMANGA_ID then Result:= KISSMANGA_NAME
  else
  if ID = BATOTO_ID then Result:= BATOTO_NAME
  else
  if ID = MANGA24H_ID then Result:= MANGA24H_NAME
  else
  if ID = VNSHARING_ID then Result:= VNSHARING_NAME
  else
  if ID = HENTAI2READ_ID then Result:= HENTAI2READ_NAME
  else
  if ID = FAKKU_ID then Result:= FAKKU_NAME
  else
  if ID = MANGAREADER_ID then Result:= MANGAREADER_NAME
  else
  if ID = MANGAPARK_ID then Result:= MANGAPARK_NAME
  else
  if ID = GEHENTAI_ID then Result:= GEHENTAI_NAME
  else
  if ID = MANGAFOX_ID then Result:= MANGAFOX_NAME
  else
  if ID = MANGATRADERS_ID then Result:= MANGATRADERS_NAME
  else
  if ID = MANGASTREAM_ID then Result:= MANGASTREAM_NAME
  else
  if ID = MANGAEDEN_ID then Result:= MANGAEDEN_NAME
  else
  if ID = PERVEDEN_ID then Result:= PERVEDEN_NAME
  else
  if ID = TRUYENTRANHTUAN_ID then Result:= TRUYENTRANHTUAN_NAME
  else
  if ID = TURKCRAFT_ID then Result:= TURKCRAFT_NAME
  else
  if ID = MANGAVADISI_ID then Result:= MANGAVADISI_NAME
  else
  if ID = EATMANGA_ID then Result:= EATMANGA_NAME
  else
  if ID = BLOGTRUYEN_ID then Result:= BLOGTRUYEN_NAME
  else
  if ID = MANGAFRAME_ID then Result:= MANGAFRAME_NAME
  else
  if ID = STARKANA_ID then Result:= STARKANA_NAME;
end;

function  GetMangaDatabaseURL(const name: String): String;
var
  i: Byte;
begin
 // result:= 'http://aarnet.dl.sourceforge.net/project/fmd/FMD/lists/'+name+'.zip';
 // result:= 'http://tenet.dl.sourceforge.net/project/fmd/FMD/lists/'+name+'.zip';
  i:= Random(2);
  case i of
    0: result:= 'http://ufpr.dl.sourceforge.net/project/fmd/FMD/lists/'+name+'.zip';
    1: result:= 'http://freefr.dl.sourceforge.net/project/fmd/FMD/lists/'+name+'.zip';
 //   0: result:= 'http://heanet.dl.sourceforge.net/project/fmd/FMD/lists/'+name+'.zip';
 //   1: result:= 'http://hivelocity.dl.sourceforge.net/project/fmd/FMD/lists/'+name+'.zip';
  end;
end;

function  RemoveSymbols(const input: String): String;
var
  i     : Cardinal;
  isDone: Boolean;
begin
  Result:= input;
  repeat
    isDone:= TRUE;
    for i:= 0 to 8 do
      if Pos(Symbols[i], Result)<>0 then
      begin
        isDone:= FALSE;
        Result:= StringReplace(Result, Symbols[i], '', [rfReplaceAll]);
      end;
  until isDone;
  if (Length(Result)>0) AND
     (Result[Length(Result)] = '.') then
  begin
    Result[Length(Result)]:= '-';
  end;
end;

function  GetString(const source, sStart, sEnd: String): String;
var
  l: Word;
  s: String;
begin
  Result:= '';
  l:= Pos(sStart, source);
  if (l<>0) AND (source[l+Length(sStart)]<>sEnd[1]) then
  begin
    s:= RightStr(source, Length(source)-l-Length(sStart)+1);
    l:= Pos(sEnd, s);
    if (l<>0) then
      Result:= LeftStr(s, l-1);
  end;
end;

function  Find(const S: String; var List: TStringList; out index: Integer): Boolean;
var
  i: Cardinal;
begin
  Result:= FALSE;
  index:= -1;
  if List.Count = 0 then exit;
  for i:= 0 to List.Count-1 do
  begin
    if CompareStr(S, List.Strings[i])=0 then
    begin
      index:= i;
      Result:= TRUE;
      break;
    end;
  end;
end;

procedure GetParams(const output: TStringList; input: String);
var l: Word;
begin
  repeat
    l:= Pos(SEPERATOR, input);
    if l<>0 then
    begin
      output.Add(LeftStr(input, l-1));
      input:= RightStr(input, Length(input)-l-Length(SEPERATOR)+1);
    end;
  until l = 0;
end;

procedure GetParams(var output: TCardinalList; input: String);
var l: Word;
begin
  repeat
    l:= Pos(SEPERATOR, input);
    if l<>0 then
    begin
      output.Add(StrToInt(LeftStr(input, l-1)));
      input:= RightStr(input, Length(input)-l-Length(SEPERATOR)+1);
    end;
  until l = 0;
end;

function  SetParams(input: TObject): String;
var
  i: Cardinal;
begin
  Result:= '';
  if input is TStringList then
  begin
    if TStringList(input).Count = 0 then exit;
    for i:= 0 to TStringList(input).Count-1 do
      Result:= Result + TStringList(input).Strings[i] + SEPERATOR;
  end
  else
  if input is TCardinalList then
  begin
    if TCardinalList(input).Count = 0 then exit;
    for i:= 0 to TCardinalList(input).Count-1 do
      Result:= Result + IntToStr(TCardinalList(input).Items[i]) + SEPERATOR;
  end
  else
  if input is TByteList then
  begin
    if TByteList(input).Count = 0 then exit;
    for i:= 0 to TByteList(input).Count-1 do
      Result:= Result + IntToStr(TByteList(input).Items[i]) + SEPERATOR;
  end;
end;

function  SetParams(const input: array of String): String;
var
  i: Cardinal;
begin
  Result:= '';
  if Length(input) = 0 then exit;
  for i:= 0 to Length(input)-1 do
    Result:= Result + input[i] + SEPERATOR;
end;

function  FixPath(const path: String): String;
var
  i: Cardinal;
begin
  Result:= '';
  if Length(path)=0 then exit;
  for i:= 1 to Length(path) do
  begin
    if Byte(path[i])>=128 then
      Result:= Result+'_'
    else
      Result:= Result+path[i];
  end;
end;

function  GetLastDir(const path: String): String;
var
  i, p: Cardinal;
begin
  Result:= '';
  if Length(path)=0 then exit;
  i:= Length(path);
  for i:= 1 to Length(path) do
  begin
    Result:= Result+path[i];
    if path[i] = '/' then
      p:= i;
  end;
end;

function  FixLastDir(const path: String): String;
var
  i, p: Cardinal;
begin
  Result:= '';
  if Length(path)=0 then exit;
  i:= Length(path);
  for i:= 1 to Length(path) do
  begin
    Result:= Result+path[i];
    if path[i] = '/' then
      p:= i;
  end;
  for i:= p to Length(Result)-1 do
    if Byte(Result[i])>=128 then
    begin
      Delete(Result, i, 1);
      Insert('_', Result, i);
    end;
end;

function  StringFilter(const source: String): String;
begin
  if Length(source) = 0 then exit;
  Result:= StringReplace(source, '&#33;', '!', [rfReplaceAll]);
  Result:= StringReplace(Result, '&amp;amp;quot;', '"', [rfReplaceAll]);
  Result:= StringReplace(Result, '&#36;', '$', [rfReplaceAll]);
  Result:= StringReplace(Result, '&#39;', '''', [rfReplaceAll]);
  Result:= StringReplace(Result, '&#033;', '!', [rfReplaceAll]);
  Result:= StringReplace(Result, '&#036;', '$', [rfReplaceAll]);
  Result:= StringReplace(Result, '&#039;', '''', [rfReplaceAll]);
  Result:= StringReplace(Result, '&gt;', '>', [rfReplaceAll]);
  Result:= StringReplace(Result, '&lt;', '<', [rfReplaceAll]);
  Result:= StringReplace(Result, '&amp;', '&', [rfReplaceAll]);
  Result:= StringReplace(Result, '&nbsp;', '', [rfReplaceAll]);
  Result:= StringReplace(Result, '&ldquo;', '"', [rfReplaceAll]);
  Result:= StringReplace(Result, '&ldquo;', '"', [rfReplaceAll]);
  Result:= StringReplace(Result, '&rdquo;', '"', [rfReplaceAll]);
  Result:= StringReplace(Result, '&quot;', '"', [rfReplaceAll]);
  Result:= StringReplace(Result, '&lsquo;', '''', [rfReplaceAll]);
  Result:= StringReplace(Result, '&rsquo;', '''', [rfReplaceAll]);
 // Result:= StringReplace(Result, '&nbsp;', ' ', [rfReplaceAll]);
  Result:= StringReplace(Result, #10, '\n',  [rfReplaceAll]);
  Result:= StringReplace(Result, #13, '\r',  [rfReplaceAll]);
end;

function  HTMLEntitiesFilter(const source: String): String;
begin
  if Length(source) = 0 then exit;

  // uppercase

  Result:= StringReplace(source, '&Agrave;', 'À', [rfReplaceAll]);
  Result:= StringReplace(Result, '&#192;', 'À', [rfReplaceAll]);
  Result:= StringReplace(Result, '&Aacute;', 'Á', [rfReplaceAll]);
  Result:= StringReplace(Result, '&#193;', 'Á', [rfReplaceAll]);
  Result:= StringReplace(Result, '&Acirc;' , 'Â', [rfReplaceAll]);
  Result:= StringReplace(Result, '&#194;' , 'Â', [rfReplaceAll]);
  Result:= StringReplace(Result, '&Atilde;', 'Ã', [rfReplaceAll]);

  Result:= StringReplace(Result, '&Egrave;', 'È', [rfReplaceAll]);
  Result:= StringReplace(Result, '&Eacute;', 'É', [rfReplaceAll]);
  Result:= StringReplace(Result, '&Ecirc;' , 'Ê', [rfReplaceAll]);
  Result:= StringReplace(Result, '&#202;' , 'Ê', [rfReplaceAll]);
  Result:= StringReplace(Result, '&Etilde;', 'Ẽ', [rfReplaceAll]);

  Result:= StringReplace(Result, '&Igrave;', 'Ì', [rfReplaceAll]);
  Result:= StringReplace(Result, '&Iacute;', 'Í', [rfReplaceAll]);
  Result:= StringReplace(Result, '&Itilde;', 'Ĩ', [rfReplaceAll]);

  Result:= StringReplace(Result, '&ETH;'   , 'Đ', [rfReplaceAll]);

  Result:= StringReplace(Result, '&Ograve;', 'Ò', [rfReplaceAll]);
  Result:= StringReplace(Result, '&Oacute;', 'Ó', [rfReplaceAll]);
  Result:= StringReplace(Result, '&Ocirc;' , 'Ô', [rfReplaceAll]);
  Result:= StringReplace(Result, '&#212;' , 'Ô', [rfReplaceAll]);
  Result:= StringReplace(Result, '&Otilde;', 'Õ', [rfReplaceAll]);

  Result:= StringReplace(Result, '&Ugrave;', 'Ù', [rfReplaceAll]);
  Result:= StringReplace(Result, '&Uacute;', 'Ú', [rfReplaceAll]);

  Result:= StringReplace(Result, '&Yacute;', 'Ý', [rfReplaceAll]);
  Result:= StringReplace(Result, '&#221;', 'Ý', [rfReplaceAll]);

  // lowercase

  Result:= StringReplace(Result, '&agrave;', 'à', [rfReplaceAll]);
  Result:= StringReplace(Result, '&#224;', 'à', [rfReplaceAll]);
  Result:= StringReplace(Result, '&aacute;', 'á', [rfReplaceAll]);
  Result:= StringReplace(Result, '&#225;', 'á', [rfReplaceAll]);
  Result:= StringReplace(Result, '&acirc;' , 'â', [rfReplaceAll]);
  Result:= StringReplace(Result, '&#226;' , 'â', [rfReplaceAll]);
  Result:= StringReplace(Result, '&atilde;', 'ã', [rfReplaceAll]);
  Result:= StringReplace(Result, '&#227;', 'ã', [rfReplaceAll]);

  Result:= StringReplace(Result, '&egrave;', 'è', [rfReplaceAll]);
  Result:= StringReplace(Result, '&#232;', 'è', [rfReplaceAll]);
  Result:= StringReplace(Result, '&eacute;', 'é', [rfReplaceAll]);
  Result:= StringReplace(Result, '&#233;', 'é', [rfReplaceAll]);
  Result:= StringReplace(Result, '&etilde;', 'ẽ', [rfReplaceAll]);
  Result:= StringReplace(Result, '&ecirc;' , 'ê', [rfReplaceAll]);
  Result:= StringReplace(Result, '&#234;' , 'ê', [rfReplaceAll]);

  Result:= StringReplace(Result, '&igrave;', 'ì', [rfReplaceAll]);
  Result:= StringReplace(Result, '&#236;', 'ì', [rfReplaceAll]);
  Result:= StringReplace(Result, '&iacute;', 'í', [rfReplaceAll]);
  Result:= StringReplace(Result, '&#237;', 'í', [rfReplaceAll]);
  Result:= StringReplace(Result, '&itilde;', 'ĩ', [rfReplaceAll]);

  Result:= StringReplace(Result, '&eth;'   , 'đ', [rfReplaceAll]);

  Result:= StringReplace(Result, '&ograve;', 'ò', [rfReplaceAll]);
  Result:= StringReplace(Result, '&#242;', 'ò', [rfReplaceAll]);
  Result:= StringReplace(Result, '&oacute;', 'ó', [rfReplaceAll]);
  Result:= StringReplace(Result, '&#243;', 'ó', [rfReplaceAll]);
  Result:= StringReplace(Result, '&ocirc;' , 'ô', [rfReplaceAll]);
  Result:= StringReplace(Result, '&#244;' , 'ô', [rfReplaceAll]);
  Result:= StringReplace(Result, '&otilde;', 'õ', [rfReplaceAll]);
  Result:= StringReplace(Result, '&#245;', 'õ', [rfReplaceAll]);

  Result:= StringReplace(Result, '&ugrave;', 'ù', [rfReplaceAll]);
  Result:= StringReplace(Result, '&#249;', 'ù', [rfReplaceAll]);
  Result:= StringReplace(Result, '&uacute;', 'ú', [rfReplaceAll]);
  Result:= StringReplace(Result, '&#250;', 'ú', [rfReplaceAll]);

  Result:= StringReplace(Result, '&yacute;', 'ý', [rfReplaceAll]);
  Result:= StringReplace(Result, '&#253;', 'ý', [rfReplaceAll]);
end;

procedure  CustomGenres(var output: TStringList; input: String);
var
  s: String = '';
  i: Word;
begin
  if Length(input) = 0 then exit;
  for i:= 1 to Length(input) do
  begin
    if (input[i] = ',') OR (input[i] = ';') then
    begin
      TrimLeft(TrimRight(s));
      if Length(s) <> 0 then
      begin
        output.Add(s);
        s:= '';
      end;
    end
    else
      s:= s+input[i];
  end;
  TrimLeft(TrimRight(s));
  if Length(s) <> 0 then
    output.Add(s);
end;

function  StringBreaks(const source: String): String;
begin
  if Length(source) = 0 then exit;
  Result:= source;
  Result:= StringReplace(Result, '\n', #10,  [rfReplaceAll]);
  Result:= StringReplace(Result, '\r', #13,  [rfReplaceAll]);
end;

function  RemoveStringBreaks(const source: String): String;
begin
  if Length(source) = 0 then exit;
  Result:= StringReplace(source, #10, '', [rfReplaceAll]);
  Result:= StringReplace(Result, #13, '', [rfReplaceAll]);
end;

function  PrepareSummaryForHint(const source: String):  String;
var
  i: Cardinal = 1;
  j: Cardinal = 1;
begin
  Result:= source;
  repeat
    if (j>80) AND (Result[i] = ' ') then
    begin
      Insert(#10#13, Result, i);
      Inc(i, 2);
      j:= 1;
    end;
    Inc(j);
    Inc(i);
  until i >= Length(Result);
  Result:= StringReplace(Result, '\n', #10,  [rfReplaceAll]);
  Result:= StringReplace(Result, '\r', #13,  [rfReplaceAll]);
end;

function  CheckRedirect(const HTTP: THTTPSend): String;
var
  lineHeader: String;
  i: Byte;
begin
  Result:= '';
  i:= 0;
  while (Result = '') AND (i < HTTP.Headers.Count) do
  begin
    lineHeader:= HTTP.Headers[I];
    if Pos('Location: ', lineHeader) = 1 then
      Result:= Copy(lineHeader, 11, Length(lineHeader));
    Inc(i);
  end;
end;

var
  bttHTTP,
  gehHTTP: THTTPSend;

// will remove this later
function  gehGetPage(var output: TObject; URL: String; const Reconnect: Cardinal; const lURL: String = ''): Boolean;
var
  code   : Cardinal;
  counter: Cardinal = 0;
  s      : String;
label
  globReturn;
begin
  if (lURL <> '') AND (Pos('?nw=session', URL) > 0) then
  begin
    Delete(URL, Length(URL)-10, 11);
    URL:= URL + lURL;
  end;

  Result:= FALSE;

globReturn:
  gehHTTP.ProxyHost:= Host;
  gehHTTP.ProxyPort:= Port;
  gehHTTP.ProxyUser:= User;
  gehHTTP.ProxyPass:= Pass;
  gehHTTP.Headers.Insert(0, 'Referer:'+URL);

  while (NOT gehHTTP.HTTPMethod('GET', URL)) OR
        (gehHTTP.ResultCode > 500) do
  begin
    code:= gehHTTP.ResultCode;
    if Reconnect <> 0 then
    begin
      if Reconnect <= counter then
      begin
        exit;
      end;
      Inc(counter);
    end;
    gehHTTP.Clear;
    Sleep(500);
  end;
  if Pos('?nw=session', URL) > 0 then
  begin
    gehHTTP.Clear;
    Delete(URL, Length(URL)-10, 11);
   // URL:= URL + lURL;
    goto globReturn;
  end;
 // gehHTTP.Document.SaveToFile('error.txt');
  while gehHTTP.ResultCode = 302 do
  begin
    URL:= CheckRedirect(gehHTTP);
    gehHTTP.Clear;
    gehHTTP.RangeStart:= 0;

    while (NOT gehHTTP.HTTPMethod('GET', URL)) OR
        (gehHTTP.ResultCode >= 500) do
    begin
      if Reconnect <> 0 then
      begin
        if Reconnect <= counter then
        begin
          exit;
        end;
        Inc(counter);
      end;
      gehHTTP.Clear;
      Sleep(500);
    end;
  end;
  if output is TStringList then
    TStringList(output).LoadFromStream(gehHTTP.Document)
  else
  if output is TPicture then
    TPicture(output).LoadFromStream(gehHTTP.Document);
  Result:= TRUE;
  gehHTTP.Clear;
end;

// will remove this later
function  bttGetPage(var output: TObject; URL: String; const Reconnect: Cardinal): Boolean;
var
  code   : Cardinal;
  counter: Cardinal = 0;
  s      : String;
begin
  Result:= FALSE;
  bttHTTP.ProxyHost:= Host;
  bttHTTP.ProxyPort:= Port;
  bttHTTP.ProxyUser:= User;
  bttHTTP.ProxyPass:= Pass;

  bttHTTP.Clear;
  bttHTTP.MimeType:= 'Content-Type: application/x-www-form-urlencoded';
  bttHTTP.KeepAlive:= TRUE;
  bttHTTP.KeepAliveTimeout:= 1000;

  while (NOT bttHTTP.HTTPMethod('GET', URL)) OR
        (bttHTTP.ResultCode > 500) do
  begin
    code:= bttHTTP.ResultCode;
    if Reconnect <> 0 then
    begin
      if Reconnect <= counter then
      begin
        exit;
      end;
      Inc(counter);
    end;
    bttHTTP.Clear;
    Sleep(500);
  end;
 // bttHTTP.Document.SaveToFile('error.txt');
  while bttHTTP.ResultCode = 302 do
  begin
    URL:= CheckRedirect(bttHTTP);
    bttHTTP.Clear;
    bttHTTP.RangeStart:= 0;

    while (NOT bttHTTP.HTTPMethod('GET', URL)) OR
        (bttHTTP.ResultCode >= 500) do
    begin
      if Reconnect <> 0 then
      begin
        if Reconnect <= counter then
        begin
          exit;
        end;
        Inc(counter);
      end;
      bttHTTP.Clear;
      Sleep(500);
    end;
  end;
  if output is TStringList then
    TStringList(output).LoadFromStream(bttHTTP.Document)
  else
  if output is TPicture then
    TPicture(output).LoadFromStream(bttHTTP.Document);
  Result:= TRUE;
  bttHTTP.Clear;
end;

function  GetPage(var output: TObject; URL: String; const Reconnect: Cardinal; const isByPassHTTP: Boolean = FALSE): Boolean;
var
  HTTP   : THTTPSend;
  code   : Cardinal;
  counter: Cardinal = 0;
  s      : String;
label
  globReturn;
begin
{ if (lURL <> '') AND (Pos('?nw=session', URL) > 0) then
  begin
    Delete(URL, Length(URL)-10, 11);
    URL:= URL + lURL;
  end; }

  Result:= FALSE;
  if (isByPassHTTP) AND (Pos('HTTP://', UpCase(URL)) = 0) then
    exit;
  HTTP:= THTTPSend.Create;
globReturn:
  HTTP.ProxyHost:= Host;
  HTTP.ProxyPort:= Port;
  HTTP.ProxyUser:= User;
  HTTP.ProxyPass:= Pass;

  if Pos(GEHENTAI_ROOT, URL) <> 0 then
    HTTP.Headers.Insert(0, 'Referer:'+URL)
  else
  if Pos(BATOTO_ROOT, URL) <> 0 then
  begin
    HTTP.MimeType:= 'Content-Type: application/x-www-form-urlencoded';
    HTTP.KeepAlive:= TRUE;
    HTTP.KeepAliveTimeout:= 1000;
  end;

  while (NOT HTTP.HTTPMethod('GET', URL)) OR
        (HTTP.ResultCode > 500) do
  begin
    code:= HTTP.ResultCode;
    if Reconnect <> 0 then
    begin
      if Reconnect <= counter then
      begin
        HTTP.Free;
        exit;
      end;
      Inc(counter);
    end;
    HTTP.Clear;
    Sleep(500);
  end;
  if Pos('?nw=session', URL) > 0 then
  begin
    HTTP.Clear;
    Delete(URL, Length(URL)-10, 11);
   // URL:= URL + lURL;
    goto globReturn;
  end;
 // HTTP.Document.SaveToFile('error2.txt');
  while HTTP.ResultCode = 302 do
  begin
    s:= CheckRedirect(HTTP);
    if Pos('http://', s) = 0 then
      URL:= 'http://' + GetString(URL, 'http://', '/');
    URL:= URL + s;

    HTTP.Clear;
    HTTP.RangeStart:= 0;
    if Pos(HENTAI2READ_ROOT, URL) <> 0 then
      HTTP.Headers.Insert(0, 'Referer:'+HENTAI2READ_ROOT+'/');
    while (NOT HTTP.HTTPMethod('GET', URL)) OR
        (HTTP.ResultCode >= 500) do
    begin
      if Reconnect <> 0 then
      begin
        if Reconnect <= counter then
        begin
          HTTP.Free;
          exit;
        end;
        Inc(counter);
      end;
      HTTP.Clear;
      Sleep(500);
    end;
  end;
  if output is TStringList then
    TStringList(output).LoadFromStream(HTTP.Document)
  else
  if output is TPicture then
    TPicture(output).LoadFromStream(HTTP.Document);
  HTTP.Free;
  Result:= TRUE;
end;

function  SavePage(URL: String; const Path, name: String; const Reconnect: Cardinal): Boolean;
var
  header  : array [0..3] of Byte;
  ext     : String;
  HTTP    : THTTPSend;
 // Memory  : TMemoryStream;
  counter : Cardinal = 0;
begin
  Result:= FALSE;
  HTTP:= THTTPSend.Create;
  HTTP.ProxyHost:= Host;
  HTTP.ProxyPort:= Port;
  HTTP.ProxyUser:= User;
  HTTP.ProxyPass:= Pass;
  if Pos(HENTAI2READ_ROOT, URL) <> 0 then
    HTTP.Headers.Insert(0, 'Referer:'+HENTAI2READ_ROOT+'/');
  while (NOT HTTP.HTTPMethod('GET', URL)) OR
        (HTTP.ResultCode >= 500) do
  begin
    if Reconnect <> 0 then
    begin
      if Reconnect <= counter then
      begin
        HTTP.Free;
        exit;
      end;
      Inc(counter);
    end;
    HTTP.RangeStart:= HTTP.Document.Size;
   // HTTP.Clear;
    Sleep(500);
  end;

  while HTTP.ResultCode = 302 do
  begin
    URL:= CheckRedirect(HTTP);
    HTTP.Clear;
    HTTP.RangeStart:= 0;
    if Pos(HENTAI2READ_ROOT, URL) <> 0 then
      HTTP.Headers.Insert(0, 'Referer:'+HENTAI2READ_ROOT+'/');
    while (NOT HTTP.HTTPMethod('GET', URL)) OR
        (HTTP.ResultCode >= 500) do
    begin
      if Reconnect <> 0 then
      begin
        if Reconnect <= counter then
        begin
          HTTP.Free;
          exit;
        end;
        Inc(counter);
      end;
      HTTP.RangeStart:= HTTP.Document.Size;
     // HTTP.Clear;
      Sleep(500);
    end;
  end;
  HTTP.Document.Seek(0, soBeginning);
  HTTP.Document.Read(header[0], 4);
  if (header[0] = JPG_HEADER[0]) AND
     (header[1] = JPG_HEADER[1]) AND
     (header[2] = JPG_HEADER[2]) then
    ext:= '.jpg'
  else
  if (header[0] = PNG_HEADER[0]) AND
     (header[1] = PNG_HEADER[1]) AND
     (header[2] = PNG_HEADER[2]) then
    ext:= '.png'
  else
  if (header[0] = GIF_HEADER[0]) AND
     (header[1] = GIF_HEADER[1]) AND
     (header[2] = GIF_HEADER[2]) then
    ext:= '.gif'
  else
    ext:= '';

 // SetCurrentDirUTF8();
 // HTTP.Document.SaveToFile('/home/akarin/FreeSpace/FMD/trunk/mangadownloader/downloads/' + name+ext);
  HTTP.Document.SaveToFile(Path+name+ext);
  HTTP.Free;
  Result:= TRUE;
end;

procedure QuickSortData(var merge: TStringList);
var
  names, output: TStringList;

  procedure QSort(L, R: Cardinal);
  var i, j: Cardinal;
         X: String;
  begin
    X:= names.Strings[(L+R) div 2];
    i:= L;
    j:= R;
    repeat
      while StrComp(PChar(names.Strings[i]), PChar(X))<0 do Inc(i);
      while StrComp(PChar(names.Strings[j]), PChar(X))>0 do Dec(j);
      if i<=j then
      begin
        names.Exchange(i, j);
        merge.Exchange(i, j);
        Inc(i);
        Dec(j);
      end;
    until i>j;
    if L < j then QSort(L, j);
    if i < R then QSort(i, R);
  end;

var
  i: Cardinal;

begin
  names := TStringList.Create;
  output:= TStringList.Create;
  for i:= 0 to merge.Count-1 do
  begin
    output.Clear;
    GetParams(output, merge.Strings[i]);
    names.Add(output.Strings[DATA_PARAM_NAME]);
  end;
  QSort(1, names.Count-1);
  output.Free;
  names.Free;
end;

// this procedure is similar to QuickSortData except it sort the siteID as well
procedure QuickSortDataWithWebID(var merge: TStringList; const webIDList: TByteList);
var
  names, output: TStringList;

  procedure QSort(L, R: Cardinal);
  var i, j: Cardinal;
         X: String;
  begin
    X:= names.Strings[(L+R) div 2];
    i:= L;
    j:= R;
    repeat
      while StrComp(PChar(names.Strings[i]), PChar(X))<0 do Inc(i);
      while StrComp(PChar(names.Strings[j]), PChar(X))>0 do Dec(j);
      if i<=j then
      begin
        names.Exchange(i, j);
        merge.Exchange(i, j);
        webIDList.Exchange(i, j);
        Inc(i);
        Dec(j);
      end;
    until i>j;
    if L < j then QSort(L, j);
    if i < R then QSort(i, R);
  end;

var
  i: Cardinal;

begin
  names := TStringList.Create;
  output:= TStringList.Create;
  for i:= 0 to merge.Count-1 do
  begin
    output.Clear;
    GetParams(output, merge.Strings[i]);
    names.Add(output.Strings[DATA_PARAM_NAME]);
  end;
  QSort(1, names.Count-1);
  output.Free;
  names.Free;
end;

function  GetCurrentJDN: LongInt;
var
  day, month, year: Word;
  a, y, m         : Single;
begin
  DecodeDate(Now, year, month, day);
  a:= (14 - month) / 12;
  y:= year + 4800 - a;
  m:= month + 12*a - 3;
  Result:= Round(day + (153*m+2)/5 + 365*y + y/4 - y/100 + y/400 - 32045);
end;

{function  ConvertInt32ToStr(const aValue: Cardinal)  : String;
begin
  Result:= '';
  Result:= Result+Char(aValue);
  Result:= Result+Char(aValue shr 8);
  Result:= Result+Char(aValue shr 16);
  Result:= Result+Char(aValue shr 24);
end;

function  ConvertStrToInt32(const aStr  : String): Cardinal;
begin
  Result:= (Byte(aStr[4]) shl 24) OR
           (Byte(aStr[3]) shl 16) OR
           (Byte(aStr[2]) shl 8) OR
            Byte(aStr[1]);
end;}

procedure TransferMangaInfo(var dest: TMangaInfo; const source: TMangaInfo);
var
  i: Cardinal;
begin
  dest.url        := source.url;
  dest.title      := source.title;
  dest.link       := source.link;
  dest.website    := source.website;
  dest.coverLink  := source.coverLink;
  dest.authors    := source.authors;
  dest.artists    := source.artists;
  dest.genres     := source.genres;
  dest.status     := source.status;
  dest.summary    := source.summary;
  dest.numChapter := source.numChapter;
  dest.chapterName .Clear;
  dest.chapterLinks.Clear;
  if source.chapterLinks.Count <> 0 then
    for i:= 0 to source.chapterLinks.Count-1 do
    begin
      dest.chapterName .Add(source.chapterName .Strings[i]);
      dest.chapterLinks.Add(source.chapterLinks.Strings[i]);
    end;
end;

constructor TDownloadPageThread.Create(CreateSuspended: Boolean);
begin
  isDone:= FALSE;
  FreeOnTerminate:= TRUE;
  inherited Create(CreateSuspended);
end;

procedure   TDownloadPageThread.Execute;
begin
 // isSuccess:= SavePage(URL, Path, Retry);
  isDone   := TRUE;
  Suspend;
end;

// OS dependent

function    fmdGetTempPath: String;
var
  l: Cardinal;
begin
{$IFDEF WINDOWS}
  SetLength(Result, 4096);
  l:= GetTempPath(4096, PChar(Result));
  SetLength(Result, l+1);
{$ENDIF}
end;

function  fmdGetTickCount: Cardinal;
begin
 {$IFDEF WINDOWS}
  Result:= GetTickCount;
 {$ENDIF}
end;

procedure fmdPowerOff;
const
  SE_SHUTDOWN_NAME = 'SeShutdownPrivilege';
begin
{$IFDEF WINDOWS}
  if IsPwrShutdownAllowed then
  begin
    NTSetPrivilege(SE_SHUTDOWN_NAME, True);
    ExitWindowsEx(EWX_POWEROFF OR EWX_FORCE, 0);
  end;
{$ENDIF}
end;

begin
  gehHTTP:= THTTPSend.Create;
  bttHTTP:= THTTPSend.Create;
 // bttHTTP.Headers.Insert(0, 'Referer:'+BATOTO_ROOT+'/');
end.