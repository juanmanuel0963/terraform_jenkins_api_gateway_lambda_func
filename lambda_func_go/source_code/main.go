package main

import (
	"log"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

func main() {
	lambda.Start(Handler_lambda_func)
}

func Handler_lambda_func(request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {

	msg := "Hello there"
	log.Println(msg)

	response := events.APIGatewayProxyResponse{
		StatusCode: 200,
		Body:       msg,
	}

	return response, nil
}
