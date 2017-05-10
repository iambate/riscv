#include<stdio.h>
int main(){
  int a[25][25], b[25][25];
  int result[25][25];
  int i,j, k;
  for(i=0;i<25;i++) {
    for(j=0;j<25;j++) {
      a[i][j] = i*25+j;
      b[i][j] = i*25+100;
    }
  }


  for(i=0;i<25;i++) {
    for(j=0;j<25;j++) {
      result[i][j] = 0;
      for(k=0;k<25;k++) {
        result[i][j]+=a[i][k]*a[k][j];
      }
    }
  }

  for(i=0;i<25;i++) {
    for(j=0;j<25;j++) {
      printf("Result[%d][%d] = %d\n",i,j, result[i][j]);
    }
  }

}
