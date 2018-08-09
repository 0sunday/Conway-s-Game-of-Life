#include <stdio.h>
#include <stdlib.h>
#define M 32
#define KNRM  "\x1B[0m"
#define KRED  "\x1B[31m"
#define KGRN  "\x1B[32m"
#define KYEL  "\x1B[33m"
#define KBLU  "\x1B[34m"
#define KMAG  "\x1B[35m"
#define KCYN  "\x1B[36m"
#define KWHT  "\x1B[37m"


__global__
void uni_func(int *A,int width,int *OUT)
{
		int col = blockIdx.x*blockDim.x + threadIdx.x;
		int row = blockIdx.y*blockDim.y + threadIdx.y;

		int n[8];//neighboors
		//oria kadrou
		bool first_row,last_row,first_col,last_col;
		first_row = col>=0 && col <= width-1;//prwti grammi = 0
		last_row = (col>=(width*width)-width) && (col<=(width*width)-1) ;//teleutaia grammi = 0
		first_col = col%width == 0;//prwti stili = 0
		last_col = col%width == width -1 ;

		if ( first_row || last_row || first_col || last_col ) {
			OUT[col] = 0;
		}
		else{
			n[0] = A[(col-1-width)] ;
			n[1] = A[(col-width)] ;
			n[2] = A[(col+1-width)] ;

			n[3] = A[(col-1)] ;//ditikos geitonas
			int iam = A[row*width + col] ; // κεντρικο κελι
			n[4] = A[(col+1)] ;//anatolikos geitonas

			n[5] = A[(col-1+width)] ;
			n[6] = A[(col+width)] ;
			n[7] = A[(col+1+width)] ;



			//on || off || dying
			//3 counters
			int counter_alive=0;
			int counter_dead=0;
			int counter_DYING=0;

			// rules: -1: dying && 0:off && 1:on
			//to parakatw for einai gia ton ipologismo twn counter

			for (int i = 0; i <= 7; i++)
			{
				if (n[i] != -1)//for sure is not dying - actually is not -1(negative number)
				{
					counter_alive += n[i];//counter_alive = counter_alive + 0/1
				}
				else//n[i] = -1
				{
					counter_DYING -= n[i] ;//-(-1)=+1
				}
			}
			counter_dead = 8 - ( counter_alive + counter_DYING);//all neighboors - not_dead


			//ti na kanw me emena???
			//parakatw tha tsekaroume to thread kai tous geitones tou
			if(iam == -1)//i am dying
			{
				iam = 0;//i will be off
			}
			else if(iam == 1)//i am on
			{
			 	iam = -1;	//i am dying
			}
			else if(iam == 0 && counter_alive == 2 )//i am off and 2 neighboors on
			{
				iam = 1;	//i will be on
			}

			//update me
			OUT[row*width + col] = iam;
		}//end else

}

int main() {

	int i,j;
	int on=0;
	int off=0;
	int dying=0;
	int N=M*M;//all elements of A
	int A[M][M] ;
	int OUT[M][M] ;
	srand (time(NULL));
	printf("\n....IN MAIN...\n");
	for(i=0;i< M;i++)
	{
		for(j=0;j< M;j++)
		{
			if (i==0 || i==M-1 || j==M-1 || j==0){
				A[i][j] = 0;//to perigramma tou pinaka
				OUT[i][j] = 0;
			}
			else{
				A[i][j]=  rand()%3 -1;

				OUT[i][j] = -999;
			}
		}
		//printf("\n");
	}
	for(i=0;i< M;i++)
	{
		for(j=0;j< M;j++)
		{
			if (A[i][j] == -1){printf("%d ", A[i][j]);}
			else{printf(" %d ", A[i][j]);}
		}
		printf("\n");
	}
	//launching kernel

	int *A_device;//int A_size = N*sizeof(int) ;
	const size_t A_size = sizeof(int) * size_t(N);
	cudaMalloc((void **)&A_device, A_size);

	int *OUT_device;//int A_size = N*sizeof(int) ;
	const size_t OUT_size = sizeof(int) * size_t(N);
	cudaMalloc((void **)&OUT_device, OUT_size);

	cudaMemcpy(A_device, A, A_size, cudaMemcpyHostToDevice);
	cudaMemcpy(OUT_device, OUT, OUT_size, cudaMemcpyHostToDevice);


	//the game is on Mrs. Hudson :)

	int turn = 0;

	while (1){

		if (turn % 2 == 0){//zigos arithmos seiras: A->in, Out->Out
			/*
			//VGALE ME AN THES NA DEIS XRONO EKTELESI
			//THIS_BLOCK_IN
			cudaEvent_t start,stop;
			float elapsedTime;
			cudaEventCreate(&start);
			cudaEventRecord(start,0);
			uni_func<<<M,M>>>(A_device,M,OUT_device);
			cudaEventCreate(&stop);
			cudaEventRecord(stop,0);
			cudaEventSynchronize(stop);
			cudaEventElapsedTime(&elapsedTime,start,stop);
			printf("\net:%f\n",elapsedTime);
			break;
			//END_OF_BLOCK
			*/

			//VGALE TIN KATW AN THES NA DEIS XRONO EKTELESI
			uni_func<<<M,M>>>(A_device,M,OUT_device);
			cudaMemcpy(OUT, OUT_device, A_size,  cudaMemcpyDeviceToHost);//thats work
			printf("\n\n-------------\n\n%d Time\n\n\n\n",turn);

			for(i=0;i< M;i++)
			{
				for(j=0;j< M;j++)
				{
					if (OUT[i][j] == -1){printf("%s%d ",KRED, OUT[i][j]);}
					else if (OUT[i][j] == 1){printf(" %s%d ",KGRN, OUT[i][j]);}
					else{printf(" %s%d ",KNRM, OUT[i][j]);}

					//make counter
					if (OUT[i][j] == -1){ dying++;}
					else if (OUT[i][j] == 1) {on++;}
					else {off++;}


				}
				printf("\n");
			}
		}
		else{
			uni_func<<<M,M>>>(OUT_device,M,A_device);
			cudaMemcpy(A, A_device, A_size,  cudaMemcpyDeviceToHost);
			printf("\n\n-------------\n\n%d Time\n\n\n\n",turn);

			for(i=0;i< M;i++)
			{
				for(j=0;j< M;j++)
				{
					if (A[i][j] == -1){printf("%s%d ",KRED, A[i][j]);}
					else if (A[i][j]==1){printf(" %s%d ",KGRN, A[i][j]);}
					else {printf(" %s%d ",KNRM, A[i][j]);}

					//make counter
					if (A[i][j] == -1){ dying++;}
					else if (A[i][j] == 1) {on++;}
					else {off++;}
				}
				printf("\n");
			}
		}
		//print counter
		printf("\n%s----------------------------------------------------\n",KNRM);
		printf("counter_alive: %d, counter_dying: %d, counter_dead: %d\n",on,dying,off);
		printf("--------------------------------------------------------\n");
		//counters = 0
		if (off == N){break;}//all elements are off (N=M*M)
		on = 0;
		off = 0;
		dying = 0;
		turn++;//auksanoume seira gia na kalesoume uni_func me allagi eisodwn-eksodwn


	}



	return 0;
}
