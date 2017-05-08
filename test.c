#include<stdio.h>
int main() {
	char a;
	printf("Please enter a number\n");
	scanf("%c", &a);
	a=a+a;
	printf("The sum is : %d\n", a);
	return 0;
}
