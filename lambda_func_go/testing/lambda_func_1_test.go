package main

import (
	"net/http"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go/aws/credentials"
	v4 "github.com/aws/aws-sdk-go/aws/signer/v4"
)

//Test with AWS signature
func Test_with_aws_signature(t *testing.T) {

	creds := credentials.NewStaticCredentials("ACCESS_KEY", "SECRET_KEY", "")

	signer := v4.NewSigner(creds)

	req, err := http.NewRequest("GET", url_address_lambda_func, nil)
	if err != nil {
		t.Errorf("expect not no error, got %v", err)
	}

	_, err = signer.Sign(req, nil, "execute-api", "us-east-1", time.Now())
	if err != nil {
		t.Errorf("expect not no error, got %v", err)
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Errorf("expect not no error, got %v", err)
	}
	if e, a := http.StatusOK, resp.StatusCode; e != a {
		t.Errorf("expect %v, got %v", e, a)
	}
}
