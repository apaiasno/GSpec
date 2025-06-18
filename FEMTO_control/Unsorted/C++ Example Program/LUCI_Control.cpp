//
//	LUCI_Control.cpp	
//
//	Steuerprogramm f�r das LUCI-10 USB Interface, zum Test der DLL
//			
//
//	Aktueller Stand: CG 20.03.17
//
//	22.11.16	Neu aufgesetzt ohne MFC f�r 64-Bit Build
//


#include "LUCI_Control.h"
#include "LUCI_10.h"
#pragma comment(lib, "user32.lib")

// Globale Variablen:
HINSTANCE hInst;								// Aktuelle Instanz
int	num_LUCI_devices;		// wieviele LUCI_10 sind angeschlossen?
int indexLUCI;				// welche der LUCIs ist gerade ausgew�hlt?
int errCode;
const int glolen = 100;
char glostring[glolen];
char glostring_2[glolen];

// Globale Funktionen
void WriteOutputData(HWND hWnd);
void UpdateDeviceList(HWND hWnd);
void GetIndexDeviceList(HWND hWnd);
void ReadID(HWND hWnd);
void WriteID(HWND hWnd);
void TestPin5(HWND hWnd);
void TestPin6(HWND hWnd);
void TestPin7(HWND hWnd);

// Vorw�rtsdeklarationen der in diesem Codemodul enthaltenen Funktionen:
BOOL				InitInstance(HINSTANCE, int);
LRESULT CALLBACK	WndProc(HWND, UINT, WPARAM, LPARAM);
INT_PTR CALLBACK	About(HWND, UINT, WPARAM, LPARAM);

int APIENTRY _tWinMain(HINSTANCE hInstance,
                     HINSTANCE hPrevInstance,
                     LPTSTR    lpCmdLine,
                     int       nCmdShow)
{
	UNREFERENCED_PARAMETER(hPrevInstance);
	UNREFERENCED_PARAMETER(lpCmdLine);

	MSG msg;
	// Anwendungsinitialisierung ausf�hren:
	if (!InitInstance (hInstance, nCmdShow))
	{
		return FALSE;
	}
	// Hauptnachrichtenschleife:
	while (GetMessage(&msg, NULL, 0, 0))
	{
        {
			TranslateMessage(&msg);
			DispatchMessage(&msg);
		}
	}
	return (int) msg.wParam;
}

//
//   FUNKTION: InitInstance(HINSTANCE, int)
//
//   ZWECK: Speichert das Instanzenhandle und erstellt das Hauptfenster.
//
//        In dieser Funktion wird das Instanzenhandle in einer globalen Variablen gespeichert, und das
//        Hauptprogrammfenster wird erstellt und angezeigt.
//
BOOL InitInstance(HINSTANCE hInstance, int nCmdShow)
{
	HWND hWnd;
	
	hInst = hInstance; // Instanzenhandle in der globalen Variablen speichern

	hWnd = CreateDialog(hInst, MAKEINTRESOURCE(IDD_DIALOG_MAIN), 0, (DLGPROC)WndProc);
 
	if (!hWnd){
		return FALSE;
	}
#ifdef _WIN64
	SetWindowText(hWnd, L"LUCI_Control  x64");
#else
	SetWindowText(hWnd, "LUCI_Control  x86");
#endif 
	UpdateDeviceList(hWnd);
	ShowWindow(hWnd, nCmdShow);
	UpdateWindow(hWnd);
	return TRUE;
}

//
//  FUNKTION: WndProc(HWND, UINT, WPARAM, LPARAM)
//
//  ZWECK:  Verarbeitet Meldungen vom Hauptfenster.
//
//  WM_COMMAND	- Verarbeiten des Anwendungsmen�s
//  WM_PAINT	- Zeichnen des Hauptfensters
//  WM_DESTROY	- Beenden-Meldung anzeigen und zur�ckgeben
//
LRESULT CALLBACK WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
	int wmId, wmEvent;
	
	switch (message)
	{
	case WM_COMMAND:
		wmId    = LOWORD(wParam);
		wmEvent = HIWORD(wParam);

		switch (wmId)
		{
		case IDC_EXIT:
			DestroyWindow(hWnd);
			break;
		case IDC_ABOUT:
			DialogBox(hInst, MAKEINTRESOURCE(IDD_ABOUTBOX), hWnd, About);
			break;
		case IDC_UPDATE_FW:
			errCode = FirmwareUpdate(indexLUCI);	// Funktion direkt aus der DLL
			break;
		case IDC_LED_ON:
			errCode = LedOn(indexLUCI);	
			break;
		case IDC_LED_OFF:
			errCode = LedOff(indexLUCI);
			break;
		case IDC_READ_ID:
			ReadID(hWnd);
			break;
		case IDC_WRITE_ID:
			WriteID(hWnd);
			break;
		case IDC_TEST_P5:
			TestPin5(hWnd);
			break;
		case IDC_TEST_P6:
			TestPin6(hWnd);
			break;
		case IDC_TEST_P7:
			TestPin7(hWnd);
			break;
		case IDC_LIST_INTERFACES:
			if(wmEvent == LBN_SELCHANGE) GetIndexDeviceList(hWnd);	// Ein Eintrag in der ListBox angecklickt	
			break;

		case IDC_CHECK0_L:
		case IDC_CHECK1_L:
		case IDC_CHECK2_L:
		case IDC_CHECK3_L:
		case IDC_CHECK4_L:
		case IDC_CHECK5_L:
		case IDC_CHECK6_L:
		case IDC_CHECK7_L:

		case IDC_CHECK0_H:
		case IDC_CHECK1_H:
		case IDC_CHECK2_H:
		case IDC_CHECK3_H:
		case IDC_CHECK4_H:
		case IDC_CHECK5_H:
		case IDC_CHECK6_H:
		case IDC_CHECK7_H:
			WriteOutputData(hWnd);
			break;
		}
		break;
	case WM_PAINT:
		break;
	case WM_DESTROY:
		PostQuitMessage(0);
		break;
	case WM_DEVICECHANGE:	// Eine LUCI an- oder abgesteckt
		if(wParam == 0x0007) UpdateDeviceList(hWnd);
		break;
	}
	return FALSE;
}

// Meldungshandler f�r Infofeld.
INT_PTR CALLBACK About(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
	UNREFERENCED_PARAMETER(lParam);
	switch (message)
	{
	case WM_INITDIALOG:
		return (INT_PTR)TRUE;
	case WM_COMMAND:
		if (LOWORD(wParam) == IDOK || LOWORD(wParam) == IDCANCEL)
		{
			EndDialog(hDlg, LOWORD(wParam));
			return (INT_PTR)TRUE;
		}
		break;
	}
	return (INT_PTR)FALSE;
}

void WriteOutputData(HWND hWnd)
{
	int indexButton;
	int data_low=0, data_high=0;

	for (indexButton = 0; indexButton < 8; indexButton++)
		if (IsDlgButtonChecked(hWnd, indexButton + IDC_CHECK0_L)) data_low += 1 << indexButton;
	for (indexButton = 0; indexButton < 8; indexButton++)
		if (IsDlgButtonChecked(hWnd, indexButton + IDC_CHECK0_H)) data_high += 1 << indexButton;

	sprintf_s(glostring, glolen, "%02X", data_low);
	SetDlgItemTextA(hWnd, IDC_EDIT_PORT_L,glostring);
	sprintf_s(glostring, glolen, "%02X", data_high);
	SetDlgItemTextA(hWnd, IDC_EDIT_PORT_H, glostring);

	errCode = WriteData(indexLUCI, data_low, data_high);
}

void WriteID(HWND hWnd)
{
	int id;

	GetDlgItemTextA(hWnd, IDC_EDIT_ID, glostring, glolen);
	sscanf_s(glostring, "%2x", &id);
	errCode = WriteAdapterID(indexLUCI, id);
	UpdateDeviceList(hWnd);
}

void ReadID(HWND hWnd)
{
	int id;

	errCode = ReadAdapterID(indexLUCI, &id);
	if (errCode == LUCI_OK) {
		sprintf_s(glostring, glolen, "%02X", id);
		SetDlgItemTextA(hWnd, IDC_EDIT_ID, glostring);
	}
	else
		SetDlgItemTextA(hWnd, IDC_EDIT_ID, "Error");
}

void TestPin5(HWND hWnd)
{
	int status;

	errCode = GetStatusPin5(indexLUCI, &status);
	if (errCode == LUCI_OK) {
		sprintf_s(glostring, glolen, "%X", status);
		SetDlgItemTextA(hWnd, IDC_EDIT_PIN5, glostring);
	}
	else
		SetDlgItemTextA(hWnd, IDC_EDIT_PIN5, "Error");
}

void TestPin6(HWND hWnd)
{
	int status;

	errCode = GetStatusPin6(indexLUCI, &status);
	if (errCode == LUCI_OK) {
		sprintf_s(glostring, glolen, "%X", status);
		SetDlgItemTextA(hWnd, IDC_EDIT_PIN6, glostring);
	}
	else
		SetDlgItemTextA(hWnd, IDC_EDIT_PIN6, "Error");
}

void TestPin7(HWND hWnd)
{
	int status;

	errCode = GetStatusPin7(indexLUCI, &status);
	if (errCode == LUCI_OK) {
		sprintf_s(glostring, glolen, "%X", status);
		SetDlgItemTextA(hWnd, IDC_EDIT_PIN7, glostring);
	}
	else
		SetDlgItemTextA(hWnd, IDC_EDIT_PIN7, "Error");
}

void GetIndexDeviceList(HWND hWnd)
{
	HWND hwndList = GetDlgItem(hWnd, IDC_LIST_INTERFACES);
	indexLUCI = (int)SendMessage(hwndList, LB_GETCURSEL, 0, 0) + 1;
}

void UpdateDeviceList(HWND hWnd)
{
	int i, err, count, id;

	HWND hwndList = GetDlgItem(hWnd, IDC_LIST_INTERFACES);
	// ListBox l�schen, falls nicht leer:
	do
		// immer den ersten Item in der Liste l�schen, die anderen rutschen nach:
		count = (int)SendMessage(hwndList, LB_DELETESTRING, 0, 0); 
	while (count > 0);
	// Bus nach LUCI_10 Interfaces durchsuchen:
	count = EnumerateUsbDevices();
	num_LUCI_devices = count;	// in globaler Variable merken
	// Geleerte Liste neu aufbauen:
	if (count == 0) {
		SendMessage(hwndList, LB_ADDSTRING, 0, (LPARAM)"No LUCI-10 Interfaces found!");
		indexLUCI = 0;
	}
	else {
		for (i = 1; i <= count; i++) {
			err = ReadAdapterID(i, &id);
			err = GetProductString(i, glostring_2, glolen);
			sprintf_s(glostring, glolen, "Interface  No %i  has  ID=%02X,   Product=\"%s\"", i, id, glostring_2);
			SendMessage(hwndList, LB_ADDSTRING, 0, (LPARAM)glostring);
		}
		// Ersten Eintrag der Liste als aktuellen ausw�hlen
		SendMessage(hwndList, LB_SETCURSEL, 0, 0);
		indexLUCI = 1;
	}
}
