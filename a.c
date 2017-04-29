//#include <unistd.h>
int main() {
	int a[5], b[5], c[5];
	for(int i=0;i<5;i++) {
		a[i] = 10;
		b[i] = 25;
	}
	for(int i=0;i<5;i++) {
		c[i] = a[i] + b[i];
	}
//	printf("%d", c[i]);
//	write(1, "Sagar", 5);
	return 0;
}
