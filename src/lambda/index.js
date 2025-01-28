exports.handler = async (event) => {
    const response = {
      statusCode: 200,
      body: JSON.stringify({
        message: "Lambda function executed successfully!",
        input: event,
      }),
    };
    return response;
  };
  