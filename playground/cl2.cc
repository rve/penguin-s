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
#define INF 0x3f3f
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

void rline();
void show(char ch,int x, int y);
#define __jmp_s {}
#define maxn 100
char ram[maxn][maxn];
int main() {
    int x= 0, y = 0;
    int lenx = 80, leny = 25;
    int dir = 1;//; 1= right, 2= down, 3 = left, 4 = up
    int circle = 13;
    int tick = INF;
    char ch = 'A';
    for (int i=0; i<leny; i++) {
        for (int j=0; j<lenx; j++) {
            ram[i][j] = ' ';
        }
    }

    
    int acc = 0;
    int endx, endy;
    x = acc; y = acc;
    endx = lenx - 1 - acc;
    endy = leny - 1 - acc;
    while(tick -- && acc < circle) {
        ;//show()j
        show(ch, x, y);
        if (1 == dir) {
            if (x == endx)
            {
                dir = 2;
                __jmp_s;
            }
            else
            x++;
        }
        else if (2 == dir) {
            if (y == endy) {
                dir = 3;
                __jmp_s;
            }
            else
                y++;
        }
        else if (3 == dir) {
            if (x == acc) {
                dir = 4;
                __jmp_s;
            }
            else 
                x--;
        }
        else if (4 == dir) {
            if (y == acc) {
                dir = 1;
                acc++;
                ch++;
                x = acc;
                y = acc;
                endx = lenx - 1 - acc;
                endy = leny - 1 - acc;
                __jmp_s;
            }
            else 
                y--;
        }

    }
    for (int i=0; i<leny; i++) {
        for (int j=0; j<lenx; j++) {
            cout<<ram[i][j];
        }
        cout<<endl;
    }


    
    

}
void show(char ch,int x, int y) 
{
    ram[y][x] = ch;

}
void rline()
{
    cout<<endl;
}
