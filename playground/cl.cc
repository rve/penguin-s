//#define LOCAL
//#define DEBUG

#include <vector>
#include <list>
#include <map>
#include <set>
#include <queue>
#include <deque>
#include <stack>
#include <bitset>
#include <algorithm>
#include <functional>
#include <numeric>
#include <utility>
#include <sstream>
#include <iostream>
#include <iomanip>
#include <cstdio>
#include <cmath>
#include <cstdlib>
#include <ctime>
#include <cstring>
#include <cassert>
#if __cplusplus > 201103L
#include <initializer_list>
#include <unordered_map>
#include <unordered_set>
#endif

using namespace std;
#define INF 0x3f3f3f3f
#ifdef DEBUG
#define cvar(x) cerr << "<" << #x << ": " << x << ">"
#define evar(x) cvar (x) << endl
#define debug(...) printf( __VA_ARGS__) 
template<class T> void DISP(const char *s, T x, int n) {cerr << "[" << s << ": "; for (int i = 0; i < n; ++i) cerr << x[i] << " "; cerr << "]" << endl;}
#define disp(x,n) DISP(#x " to " #n, x, n)
#else
#define debug(...) 
#define cvar(...) ({})
#define evar(...) ({})
#define disp(...) ({})
#endif
#define maxn 100
int main() {
    int x= 0, y = 0;
    int lenx = 80, leny = 25;
    int dir = 1;//; 1= right, 2= down, 3 = left, 4 = up
    char ram[maxn][maxn];
    int circle = 13;
    char ch = 'A';
    memset(ram, 0, sizeof(ram));
    for (int i=0; i<leny; i++) {
        for (int j=0; j<lenx; j++) {
            ram[i][j] = ' ';
        }
    }
    for(int c = 0; c <circle; c++) {
        x = y = c;
        int endx = lenx -1 -c;
        int endy = leny -1 -c;
        for (; x<=endx; x++)
        {
            ram[y][x] = ch;
        }
        x = endx;
        for (; y<=endy; y++) {
            ram[y][x] = ch;
        }
        y = endy;
        for (; x >= c; x--) {
            ram[y][x] = ch;
        }
        x = c;
        for (; y >= c; y--) {
            ram[y][x] = ch;
        }
        ch++;
    }
    evar(ram[1][79]);
    evar(ram[13][79]);
    evar(ram[23][79]);
    for (int i=0; i<leny; i++) {
        for (int j=0; j<lenx; j++) {
            cout<<ram[i][j];
        }
        cout<<endl;
    }


    
    

}
