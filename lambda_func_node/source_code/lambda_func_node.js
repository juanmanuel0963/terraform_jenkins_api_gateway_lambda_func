// Lambda function code

module.exports.handler = async (event) => {
  console.log('Event: ', event);
  let responseMessage = 'Hello there!!!';

  if (event.queryStringParameters && event.queryStringParameters['name']) {
    responseMessage = 'Hello ' + event.queryStringParameters['name'] + '!';
  }
    
  return {
    statusCode: 200,
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      message: responseMessage,
    }),
  }
}
